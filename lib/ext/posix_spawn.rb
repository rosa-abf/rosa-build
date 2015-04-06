require 'posix/spawn'

module POSIX
  module Spawn
    class Child
      include POSIX::Spawn
    private
      # Start a select loop writing any input on the child's stdin and reading
      # any output from the child's stdout or stderr.
      #
      # input   - String input to write on stdin. May be nil.
      # stdin   - The write side IO object for the child's stdin stream.
      # stdout  - The read side IO object for the child's stdout stream.
      # stderr  - The read side IO object for the child's stderr stream.
      # timeout - An optional Numeric specifying the total number of seconds
      #           the read/write operations should occur for.
      #
      # Returns an [out, err] tuple where both elements are strings with all
      #   data written to the stdout and stderr streams, respectively.
      # Raises TimeoutExceeded when all data has not been read / written within
      #   the duration specified in the timeout argument.
      # Raises MaximumOutputExceeded when the total number of bytes output
      #   exceeds the amount specified by the max argument.
      def read_and_write(input, stdin, stdout, stderr, timeout=nil, max=nil)
        max = nil if max && max <= 0
        @out, @err = '', ''
        offset = 0

        # force all string and IO encodings to BINARY under 1.9 for now
        #if @out.respond_to?(:force_encoding) and stdin.respond_to?(:set_encoding)
        #  [stdin, stdout, stderr].each do |fd|
        #    fd.set_encoding('BINARY', 'BINARY')
        #  end
        #  @out.force_encoding('BINARY')
        #  @err.force_encoding('BINARY')
        #  input = input.dup.force_encoding('BINARY') if input
        #end

        timeout = nil if timeout && timeout <= 0.0
        @runtime = 0.0
        start = Time.now

        readers = [stdout, stderr]
        writers =
          if input
            [stdin]
          else
            stdin.close
            []
          end
        slice_method = input.respond_to?(:byteslice) ? :byteslice : :slice
        t = timeout

        while readers.any? || writers.any?
          ready = IO.select(readers, writers, readers + writers, t)
          raise TimeoutExceeded if ready.nil?

          # write to stdin stream
          ready[1].each do |fd|
            begin
              boom = nil
              size = fd.write_nonblock(input)
              input = input.send(slice_method, size..-1)
            rescue Errno::EPIPE => boom
            rescue Errno::EAGAIN, Errno::EINTR
            end
            if boom || input.bytesize == 0
              stdin.close
              writers.delete(stdin)
            end
          end

          # read from stdout and stderr streams
          ready[0].each do |fd|
            buf = (fd == stdout) ? @out : @err
            begin
              buf << fd.readpartial(BUFSIZE)
            rescue Errno::EAGAIN, Errno::EINTR
            rescue EOFError
              readers.delete(fd)
              fd.close
            end
          end

          # keep tabs on the total amount of time we've spent here
          @runtime = Time.now - start
          if timeout
            t = timeout - @runtime
            raise TimeoutExceeded if t < 0.0
          end

          # maybe we've hit our max output
          if max && ready[0].any? && (@out.size + @err.size) > max
            raise MaximumOutputExceeded
          end
        end
        [@out.mb_chars.default_encoding!, @err.mb_chars.default_encoding!]
      end
    end
  end
end
