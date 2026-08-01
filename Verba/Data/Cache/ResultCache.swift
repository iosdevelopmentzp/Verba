actor ResultCache: ResultCaching {

    // MARK: Private properties

    private var storage: [String: ActionResult] = [:]
    private var accessOrder: [String] = []

    // MARK: Static

    private static let capacity = 50

    // MARK: Public methods

    func value(for key: String) async -> ActionResult? {
        guard let result = storage[key] else { return nil }
        touch(key)
        return result
    }

    func store(_ result: ActionResult, for key: String) async {
        if storage[key] == nil {
            accessOrder.append(key)
        } else {
            touch(key)
        }
        storage[key] = result
        evictIfNeeded()
    }

    // MARK: Private methods

    private func touch(_ key: String) {
        guard let index = accessOrder.firstIndex(of: key) else { return }
        accessOrder.remove(at: index)
        accessOrder.append(key)
    }

    private func evictIfNeeded() {
        while accessOrder.count > Self.capacity {
            let oldestKey = accessOrder.removeFirst()
            storage.removeValue(forKey: oldestKey)
        }
    }
}
