//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 19.12.2021.
//

import Fluent
import Vapor
import SotoS3

struct ReplaceLayoutWithItemsInWork: Migration {
    let application: Application
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Work.v2021_11_04.schemaName)
            .field(Work.v2021_12_30.bodyIndex, .int, .required, .sql(.default(0)))
            .update()
            .flatMap {
                Work.ModelReplacingLayoutWithImages.query(on: database)
                    .all()
            }
            .flatMapEachThrowing { work -> (Work.ModelReplacingLayoutWithImages, [WorkImage]) in
                let images: [WorkImage]
                let bodyIndex: Int
                let workID = try work.requireID()

                switch work.layout {
                case .leftBody:
                    bodyIndex = 0
                    images = [
                        .init(sortIndex: 0, name: work.firstImageName, workID: workID),
                        .init(sortIndex: 1, name: work.secondImageName, workID: workID)
                    ]
                case .middleBody:
                    bodyIndex = 1
                    images = [
                        .init(sortIndex: 0, name: work.firstImageName, workID: workID),
                        .init(sortIndex: 1, name: work.secondImageName, workID: workID)
                    ]
                case .rightBody:
                    bodyIndex = 2
                    images = [
                        .init(sortIndex: 0, name: work.firstImageName, workID: workID),
                        .init(sortIndex: 1, name: work.secondImageName, workID: workID)
                    ]
                case .leftLargeBody:
                    bodyIndex = 0
                    images = [
                        .init(sortIndex: 0, name: nil, workID: workID),
                        .init(sortIndex: 1, name: work.firstImageName, workID: workID)
                    ]
                case .rightLargeBody:
                    bodyIndex = 1
                    images = [
                        .init(sortIndex: 0, name: work.firstImageName, workID: workID),
                        .init(sortIndex: 1, name: nil, workID: workID)
                    ]
                }
                
                work.bodyIndex = bodyIndex

                return (work, images)
            }
            .flatMapEach(on: database.eventLoop) { work, images in
                work.save(on: database).map { images }
            }
            .map { images in images.flatMap { $0 } }
            .flatMapEach(on: database.eventLoop) { image in
                image.save(on: database)
                    .flatMap {
                        guard let imageName = image.name else {
                            return database.eventLoop.future()
                        }
                        do {
                            let dstPathComponents = try FilePathBuilder().workImagePath(for: image)
                            let request = Request(application: application, on: database.eventLoop)
                            
                            return request.fileHandler.move(imageName, at: "WorkImages", to: dstPathComponents)
                        } catch {
                            return database.eventLoop.makeFailedFuture(error)
                        }
                    }
            }
            .flatMap {
                database.schema(Work.v2021_11_04.schemaName)
                    .deleteField(Work.v2021_11_04.layout)
                    .deleteField(Work.v2021_11_04.firstImageName)
                    .deleteField(Work.v2021_11_04.secondImageName)
                    .update()
            }
            .flatMap {
                database.enum(Work.LayoutType.v2021_11_04.enumName).delete()
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database
            .enum(Work.LayoutType.v2021_11_04.enumName)
            .case(Work.LayoutType.v2021_11_04.leftBody)
            .case(Work.LayoutType.v2021_11_04.middleBody)
            .case(Work.LayoutType.v2021_11_04.rightBody)
            .case(Work.LayoutType.v2021_11_04.leftLargeBody)
            .case(Work.LayoutType.v2021_11_04.rightLargeBody)
            .create()
            .flatMap { workLayoutType in
                database.schema(Work.v2021_11_04.schemaName)
                    .field(Work.v2021_11_04.layout, workLayoutType, .required, .sql(.default("leftBody")))
                    .field(Work.v2021_11_04.firstImageName, .string)
                    .field(Work.v2021_11_04.secondImageName, .string)
                    .update()
            }
            .flatMap {
                Work.ModelReplacingLayoutWithImages.query(on: database).all()
            }
            .flatMapEach(on: database.eventLoop) { work in
                work.$images
                    .query(on: database)
                    .sort(\.$sortIndex, .ascending)
                    .all()
                    .map { images in
                        guard images.count == 2 else { return }
                        switch (work.bodyIndex, images[0].name, images[1].name) {
                        case (0, let firstImageName?, let secondImageName?):
                            work.layout = .leftBody
                            work.firstImageName = firstImageName
                            work.secondImageName = secondImageName
                        case (1, let firstImageName?, let secondImageName?):
                            work.layout = .middleBody
                            work.firstImageName = firstImageName
                            work.secondImageName = secondImageName
                        case (2, let firstImageName?, let secondImageName?):
                            work.layout = .rightBody
                            work.firstImageName = firstImageName
                            work.secondImageName = secondImageName
                        case (0, nil, let firstImageName?):
                            work.layout = .leftLargeBody
                            work.firstImageName = firstImageName
                            work.secondImageName = nil
                        case (1, let firstImageName?, nil):
                            work.layout = .rightLargeBody
                            work.firstImageName = firstImageName
                            work.secondImageName = nil
                        default:
                            break
                        }
                    }
                    .flatMap { work.save(on: database) }
            }
            .flatMap {
                WorkImage.query(on: database).all()
            }
            .flatMapEach(on: database.eventLoop) { image in
                guard let imageName = image.name else {
                    return database.eventLoop.future()
                }
                do {
                    let srcPathComponents = try FilePathBuilder().workImagePath(for: image)
                    let request = Request(application: application, on: database.eventLoop)
                    
                    return request.fileHandler.move(imageName, at: srcPathComponents, to: "WorkImages")
                } catch {
                    return database.eventLoop.makeFailedFuture(error)
                }
            }
    }
}

extension Work {
    final class ModelReplacingLayoutWithImages: Model {
        static var schema = Work.v2021_11_04.schemaName
        
        @ID
        var id: UUID?
        
        @Enum(key: Work.v2021_11_04.layout)
        var layout: LayoutType
        
        @OptionalField(key: Work.v2021_11_04.firstImageName)
        var firstImageName: String?
        
        @OptionalField(key: Work.v2021_11_04.secondImageName)
        var secondImageName: String?
        
        @Field(key: v2021_12_30.bodyIndex)
        var bodyIndex: Int
        
        @Children(for: \.$work)
        var images: [WorkImage.ModelReplacingLayoutWithImages]
        
        init() { }
    }
}

extension WorkImage {
    final class ModelReplacingLayoutWithImages: Model {
        static var schema = v2021_12_19.schemaName
        
        @ID
        var id: UUID?
        
        @Field(key: v2021_12_19.sortIndex)
        var sortIndex: Int
        
        @OptionalField(key: v2021_12_19.name)
        var name: String?
        
        @Parent(key: v2021_12_19.workID)
        var work: Work.ModelReplacingLayoutWithImages
        
        init() { }
    }
}
