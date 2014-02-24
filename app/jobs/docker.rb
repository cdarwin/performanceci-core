require_relative 'Worker/worker'
require_relative 'killabeez'
ENV['DOCKER_URL'] = 'unix:///var/run/docker.sock'
require 'fileutils'
require 'docker'
require 'git'

class DockerWorker < Worker
    include Resque::Plugins::Status
    @queue = "docker"
    def perform

      build = Build.find(options['build_id'])
      url   = build.url
      repo  = build.repository.full_name
      root  = ENV['WORKSPACE'] || '/var/cache/workspace'
      host  = ENV['HOST']      || 'localhost'
      port  = rand(8000..8999)

      base      = "#{root}/#{build.id}"
      workspace = "#{base}/#{repo}"

      at(0, 9, "Cleaning up workspace")
      FileUtils.rm_r base if Dir.exists? base

      at(1, 9, "Cloning Repo")
      Git.clone(url, workspace)
      # Check for Dockerfile and perfci.yaml
      # Read endpoints from perfci.yaml

      at(2, 9, "Building container")
      image = Docker::Image.build_from_dir(workspace)

      at(3, 9, "Running container")
      container_id = Worker.system_quietly("docker run -d -p 0.0.0.0:#{port}:4567 #{image.id}")

      at(4, 9, "Singaling KillaBeez")
      endpoints = ["/", "/test"]
      build_endpoints = endpoints.map do |uri|
        build.add_endpoint(uri, {})
      end
      job_ids = 6.times.collect do
          KillaBeez.create(:endpoints => endpoints, :host => host, :port => port)
      end

      at(5, 9, "Collecting data")
      statuses = job_ids.map do |job_id|
        status = Resque::Plugins::Status::Hash.get(job_id)
        while !status.completed? && !status.failed? do
          sleep 1
          status = Resque::Plugins::Status::Hash.get(job_id)
        end
        status['latency']
      end

      at(6, 9, "Storing stats")
      begin
        latency = []
        count = 0
        build_endpoints.each do |endpoint|
          latencies = statuses.map { |lat|  lat[count] }
          latency[count] = latencies.reduce(:+)
          latency[count] = latency[count] / 6
          build.endpoint_benchmark(endpoint, latency[count], 0, [])
          count += 1
        end
      rescue Exception => e
        puts "Error: #{e}"
        raise e
      end

      at(7, 9, "Killing container")
      container = Docker::Container.get(container_id)
      container.kill

      at(8, 9, "Cleaning workspace")
      FileUtils.rm_r base
      puts "Performance Tested!"
    end
end
