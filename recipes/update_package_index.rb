case node['platform_family']
when 'debian' # includes ubuntu
  include_recipe('apt')
when 'mac_os_x'
  ruby_block "error if homebrew is not already installed" do
    block do
      raise "You must install homebrew beforehand before running this recipe"
    end
    not_if "which brew"
  end
  execute "brew update"
when 'rhel'
  execute "yum -y update"
else
  log "Cannot update package index for platform_family=#{node['platform_family']}" do
    level :error
  end
end
