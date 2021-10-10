import Fluent
import Vapor

func routes(_ app: Application) throws {
    let worksController = WorksController()
    try app.register(collection: worksController)
    
    let usersController = UsersController()
    try app.register(collection: usersController)
    
    let profileController = ProfileController()
    try app.register(collection: profileController)
}
