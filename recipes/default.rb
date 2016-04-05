if node['particle-base']['do_update_packages']
  if platform_family?('debian')
    execute "apt-get update"
  end
end

directory node['particle-base']['dir'] do
  user node['particle-base']['user']
  group node['particle-base']['user']
  recursive true
end

node['particle-base']['packages'].each_pair do |category, pkg_array|
  Chef::Log.debug "install #{category} packages: #{pkg_array}"
  pkg_array.each do |pkg_name|
    package pkg_name
  end
end
