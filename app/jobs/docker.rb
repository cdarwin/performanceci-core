require_relative 'Worker/worker'
require_relative 'killabeez'
ENV['DOCKER_URL'] = 'unix:///var/run/docker.sock'
require 'docker'
require 'git'

class DockerWorker < Worker
    include Resque::Plugins::Status
    @queue = "docker"
    def perform
      at(0, 7, "Cleaning up workspace")
      url = options['url']
      repo = options['repo']
      path = "/tmp/#{repo}"
      host = 'http://23.253.97.212'
      port = '4567'
      endpoints = ["#{host}:#{port}/", "#{host}:#{port}/test"]
      build = Build.find(options['build_id'])
      build_endpoints = endpoints.map do |url|
        build.add_endpoint(url, {})
      end

      Worker.system_quietly("rm -rf #{path}")

      at(1, 7, "Cloning Repo")
      Git.clone(url, path)

      at(2, 7, "Building container")
      image = Docker::Image.build_from_dir(path)
      begin
        image.tag(:tag => 'latest')
      rescue Exception => e
        puts "Error #{e}"
      end

      at(3, 7, "Running container")
      container_id = Worker.system_quietly("docker run -d -p 0.0.0.0:4567:4567 #{image.id}")
      puts container_id


      at(4, 7, "Attacking container")
      job_id = KillaBeez.create(:endpoints => endpoints)
      while status = Resque::Plugins::Status::Hash.get(job_id) and !status.completed? && !status.failed?
        sleep 1
      end

      latency = status['latency']
      count = 0
      build_endpoints.each do |endpoint|
        build.endpoint_benchmark(endpoint, latency[count], 0, [])
        count += 1
      end

      at(5, 7, "Killing container")
      container = Docker::Container.get(container_id)
        container.kill
      begin
        image.remove
      rescue Exception => e
        puts "Error #{e}"
      end

      at(6, 7, "Cleaning workspace")
      Worker.system_quietly("rm -rf #{path}")
      puts "Container built"
    end
end
