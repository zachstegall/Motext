extension String {
    public func ranges(of searchString: String) -> [Range<String.Index>] {
        var ranges = [Range<String.Index>]()
        var substringSuffixStart: String.Index = self.startIndex

        while substringSuffixStart < self.endIndex, let range = self.suffix(from: substringSuffixStart).range(of: searchString) {
            ranges.append(range)
            substringSuffixStart = range.upperBound
        }

        return ranges
    }
}
