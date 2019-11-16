require 'date'

class Applitoolz

  attr_accessor :platform, :driver, :eyes, :app_name, :test_name, :keep, :tag

  def initialize options
    self.platform = options[:platform]
    self.driver = Screenshot.new options
    self.eyes = Applitools::Images::Eyes.new
    eyes.api_key = options[:apiKey]
    eyes.server_url = options[:server]
    eyes.log_handler = Logger.new(STDOUT) if options[:showLogs]
    eyes.proxy = Applitools::Connectivity::Proxy.new options[:proxy] if options[:proxy] 
    eyes.match_level = options[:matchLevel].downcase.to_sym
    eyes.baseline_env_name = options[:baseline]
    self.app_name = options[:appName]
    self.test_name = options[:testName]
    batch_info = Applitools::BatchInfo.new(options[:batchName])
    batch_info.id = options[:batchId]
    eyes.batch = batch_info
    eyes.host_app = options[:hostApp]
    eyes.host_os = options[:hostOs]
    self.keep = options[:keep]
    self.tag = options[:tag]
  end
  
  def upload_to_applitools
    image_info = driver.screenshot
    tag = image_info[:udid] if tag.nil?
    eyes.test(app_name: app_name, test_name: test_name) do
      eyes.check_image(image_path: image_info[:path], tag: image_info[:udid])
      remove_image image_info[:path] unless keep
    end
  end
  
  private
  
  def remove_image image
    File.delete image if File.exists? image
  end
end