////
////  File.swift
////  
////
////  Created by Dmitry Borodin on 26.08.2021.
////
//
//import Vapor
//import Fluent
//
//struct BookCoversController: RouteCollection {
//    func boot(routes: RoutesBuilder) throws {
//        let bookCoversRoutes = routes.grouped("api", "covers")
//        bookCoversRoutes.get(use: getAllHandler)
//        bookCoversRoutes.get(":coverID", use: getHandler)
//        bookCoversRoutes.post(use: createHandler)
//        bookCoversRoutes.put(":coverID", use: updateHandler)
//        bookCoversRoutes.delete(":coverID", use: deleteHandler)
//        bookCoversRoutes.get("search", use: searchHandler)
//        bookCoversRoutes.get("first", use: getFirstHandler)
//        bookCoversRoutes.get("sorted", use: sortedHandler)
//    }
//    
//    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[BookCover]> {
//        BookCover.query(on: req.db).all()
//    }
//    
//    func getHandler(_ req: Request) throws -> EventLoopFuture<BookCover> {
//        BookCover.find(req.parameters.get("coverID"), on: req.db)
//            .unwrap(or: Abort(.notFound))
//    }
//    
//    func createHandler(_ req: Request) throws -> EventLoopFuture<BookCover> {
//        let cover = try req.content.decode(BookCover.self)
//        
//        return cover
//            .save(on: req.db)
//            .map { cover }
//    }
//    
//    func updateHandler(_ req: Request) throws -> EventLoopFuture<BookCover> {
//        let updatedCover = try req.content.decode(BookCover.self)
//        
//        return BookCover.find(req.parameters.get("coverID"), on: req.db)
//            .unwrap(or: Abort(.notFound))
//            .flatMap { cover in
//                cover.title = updatedCover.title
//                cover.description = updatedCover.description
//                return cover.save(on: req.db)
//                    .map { cover }
//            }
//    }
//    
//    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        BookCover.find(req.parameters.get("coverID"), on: req.db)
//            .unwrap(or: Abort(.notFound))
//            .flatMap { cover in
//                cover.delete(on: req.db)
//                    .transform(to: .noContent)
//            }
//    }
//    
//    func searchHandler(_ req: Request) throws -> EventLoopFuture<[BookCover]> {
//        guard let searchTerm = req.query[String.self, at: "term"] else {
//            throw Abort(.badRequest)
//        }
//        return BookCover.query(on: req.db)
//            .group(.or) { or in
//                or.filter(\.$title == searchTerm)
//                or.filter(\.$description == searchTerm)
//            }
//            .all()
//    }
//    
//    func getFirstHandler(_ req: Request) throws -> EventLoopFuture<BookCover> {
//        BookCover.query(on: req.db)
//            .first()
//            .unwrap(or: Abort(.notFound))
//    }
//    
//    func sortedHandler(_ req: Request) throws -> EventLoopFuture<[BookCover]> {
//        BookCover.query(on: req.db)
//            .sort(\.$title, .ascending)
//            .all()
//    }
//    
//}
