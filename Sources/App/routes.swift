import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: WorksController())
    try app.register(collection: UsersController())
    try app.register(collection: ProfileController())
    try app.register(collection: SectionsController())
    try app.register(collection: WebsiteController())
    try app.register(collection: TagsController())
}
