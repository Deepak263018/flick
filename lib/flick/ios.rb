module Flick
  class Ios
    attr_accessor :flick_dir, :udid, :name, :outdir, :todir, :specs

    def initialize options
      self.udid = options.fetch(:udid, get_device_udid(options))
      self.flick_dir = "#{Dir.home}/.flick/#{udid}"
      self.name = remove_bad_characters(options.fetch(:name, self.udid))
      self.todir = options.fetch(:todir, self.flick_dir)
      self.outdir = options.fetch(:outdir, Dir.pwd)
      self.specs = options.fetch(:specs, false)
      create_flick_dirs
    end

    def remove_bad_characters string
      string.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
    end

    def create_flick_dirs
      Flick::System.setup_system_dir "#{Dir.home}/.flick"
      Flick::System.setup_system_dir flick_dir
    end

    def devices
      Flick::Checker.system_dependency "idevice_id"
      (`idevice_id -l`).split.uniq.map { |d| d }
    end

    def devices_connected?
      devices.any?
    end

    def check_for_devices
      unless devices_connected?
        puts "\nNo iPhone or iPad Devices Connected!!!\nMake sure at least one REAL device is connected!\n".red
        abort
      end
    end

    def get_device_udid opts_hash
      check_for_devices
      return unless opts_hash[:udid].nil?
      if devices.size == 1
        devices[0]
      else
        puts "\nMultiple iOS devices '#{devices}' found.\nSpecify a single UDID. e.g. -u #{devices.sample}\n".red
        abort unless specs
      end
    end

    def info
      specs = { os: "ProductVersion", name: "DeviceName", arc: "CPUArchitecture", type: "DeviceClass", sdk: "ProductType" }
      hash = { udid: udid }
      specs.each do |key, spec|
        value = (`ideviceinfo -u #{udid} | grep #{spec} | awk '{$1=""; print $0}'`).strip
        hash.merge!({key=> "#{value}"})
      end
      hash
    end

    def recordable?
      false
    end

    def clear_files
      Flick::System.clean_system_dir flick_dir
    end

    def screenshot name
      Flick::Checker.system_dependency "idevicescreenshot"
      %x(idevicescreenshot -u #{udid} #{todir}/#{name}.png)
    end

    def log name
      Flick::Checker.system_dependency "idevicesyslog"
      %x(idevicesyslog -u #{udid} > #{outdir}/#{name}.log)
    end

    def install app_path
      Flick::Checker.system_dependency "ideviceinstaller"
      %x(ideviceinstaller -u #{udid} -i #{app_path})
    end

    def uninstall package
      Flick::Checker.system_dependency "ideviceinstaller"
      if app_installed? package
        %x(ideviceinstaller -u #{udid} -U #{package})
      else
        puts packages
        puts "\n#{package} was not found on device #{udid}! Please choose one from above. e.g. #{packages.sample}\n".red
      end
    end

    def app_installed? package
      packages.include? "#{package}"
    end

    def packages
      %x(ideviceinstaller -u #{udid} -l -o list_user).split("\n")[1..100000].map { |p| p.match(/(.*) -/)[1] }
    end
  end
end