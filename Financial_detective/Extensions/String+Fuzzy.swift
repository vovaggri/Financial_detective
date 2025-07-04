extension String {
    func fuxxyMatches(_ pattern: String) -> Bool {
        let text = self.lowercased()
        let pattern = pattern.lowercased()
        var ti = text.startIndex
        var pi = pattern.startIndex
        
        while ti < text.endIndex && pi < pattern.endIndex {
            if text[ti] == pattern[pi] {
                pi = pattern.index(after: pi)
            }
            ti = text.index(after: ti)
        }
        return pi == pattern.endIndex
    }
}
