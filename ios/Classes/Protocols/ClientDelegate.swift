protocol ClientDelegate: AnyObject {
    func onClientSynchronizationChanged(status: [String: Any])
//    func onTokenStatusChange(status: String)
}
