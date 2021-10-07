import Fluent
import Vapor

func routes(_ app: Application) throws {
    let worksController = WorksController()
    try app.register(collection: worksController)
}
