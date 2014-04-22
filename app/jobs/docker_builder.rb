require 'docker'
require 'shell'

#TEST: invalid startup
#TODO: stream build logs - add property?
#TODO: Save output log - add property?
#TODO: Test single http run
#TODO: docker build in docker
#TODO: Better than random port

#TODO:

#TODO: Split out build & run
#TODO: Pass in log streamer - stream as it goes
#TODO: Exception handle on cleanup

#TODO: use hash for project config
#TODO: factory methods
class DockerBuilder
  attr_reader :src_dir, :image, :errors, :container,
              :host_port, :container_port, :build_logs

  # TODO: allow more than one export ports?
  def initialize(src_dir, project_configuration, options = {})
    @src_dir = src_dir
    @errors = []
    @container = nil
    @image = nil
    @container_port = project_configuration.configuration[:port]
    @host_port  = options[:host_port] || rand(8000..65535)
  end

  def cleanup
    container.kill if container
    image.remove if image
  rescue Exception => e
    puts "Error: #{e.to_s} #{e.backtrace}"
  end

  def build
    if build_image
      run_container
    else
      false
    end
  end

  def run_logs
    if container
      @run_logs ||= Worker.system_capture("docker logs #{container.id}".split(' '))
    end
  end

  def build_image
    begin
      #@image = Docker::Image.build_from_dir(src_dir)
      @build_logs = `cd #{src_dir} && docker build .`
      if $?.success? && @build_logs =~ /Successfully built ([\S]+)/
        @image = Docker::Image.get($1)
        true
      else
        errors << "Failed to build:\n#{@build_logs}"
        false
      end
    rescue Exception => e
      puts "Error: #{e.to_s}\n#{e.backtrace}"
      errors << e.to_s + "\n" + e.backtrace.to_s
      false
    end
  end

  def run_container
    container_id = Worker.system_quietly("docker run -d -p 0.0.0.0:#{host_port}:#{container_port} #{image.id}")
    @container = Docker::Container.get(container_id)
    true
  rescue Shell::Error => e
    puts "Error: #{e.backtrace}"
    errors << e.to_s + "\n" + e.backtrace.to_s
    false
  end

  #TODO: return hostname for multi machine builds
  def base_test_url
    "http://127.0.0.1:#{host_port}"
  end
end