import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import SotoS3

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(SSLMiddleware(enabled: true))
    
    let databaseName: String
    let databasePort: Int
    if (app.environment == .testing) {
      databaseName = "vapor-test"
      if let testPort = Environment.get("DATABASE_PORT") {
        databasePort = Int(testPort) ?? 5433
      } else {
        databasePort = 5433
      }
    } else {
      databaseName = "vapor_database"
      databasePort = 5432
    }
    
    if var config = Environment.get("DATABASE_URL")
        .flatMap(URL.init)
        .flatMap(PostgresConfiguration.init) {
        config.tlsConfiguration = .forClient(certificateVerification: .none)
        app.databases.use(.postgres(configuration: config), as: .psql)
    } else {
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: databasePort,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? databaseName
        ), as: .psql)
    }
    
    let awsClient = AWSClient(httpClientProvider: .shared(app.http.client.shared))
    app.aws.client = awsClient
    app.aws.s3 = S3(client: awsClient, region: .uswest1)
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateProfile())
    app.migrations.add(CreateWork())
    app.migrations.add(CreateTag())
    app.migrations.add(CreateWorkTagPivot())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateMainUser(environment: app.environment))
    app.migrations.add(CreateSection())
    app.migrations.add(CreateAllSections())
    
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()
    
    app.views.use(.leaf)
    
    // register routes
    try routes(app)
}
