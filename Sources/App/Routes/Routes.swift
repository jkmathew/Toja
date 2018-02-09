import Vapor

extension Droplet {
    func setupRoutes() throws {
        
        _ = BuildController(self)
    }
}
