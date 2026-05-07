package grammy4cj.test_support

import grammy4cj.core.MultipartByteStream
import grammy4cj.types.InputFile

public func fakeStreamFile(label: String, filename: String): InputFile {
    InputFile.fromStream(label, filename)
}

public func failingStreamFile(message: String, filename: String): InputFile {
    InputFile("stream_error", message, filename)
}

public func failingMultipartStream(message: String): MultipartByteStream {
    MultipartByteStream().fail(message)
}
