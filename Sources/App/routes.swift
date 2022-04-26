import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: WorksController())
    try app.register(collection: LayoutsController())
    try app.register(collection: UsersController())
    try app.register(collection: WebsiteController())
    try app.register(collection: TagsController())
    try app.register(collection: AttachmentsController())
}
