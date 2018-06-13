import Vapor

class AppWorker {
    let container: Container

    init(on container: Container) {
        self.container = container
    }
}
