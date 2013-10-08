include_recipe 'apt'
include_recipe 'java'

install_parent = File.dirname(node.bamboo.install_dir)
cache_path = Chef::Config[:file_cache_path]
tarball_path = "#{cache_path}/#{File.basename(node.bamboo.download_url)}"

user "bamboo" do
  action :create
  supports :manage_home => true
  system true
  shell "/bin/false"
  home node.bamboo.home
end

directory install_parent do
  action :create
  mode 00755
end

# Fix for Vagrant Chef provisioner
directory cache_path do
  action :create
  recursive true
end

remote_file tarball_path do
  source node.bamboo.download_url
  checksum node.bamboo.download_sha256
end

bash "install bamboo" do
  cwd install_parent
  code <<-EOS
    tar -xvzf #{tarball_path}
  EOS
  not_if { ::File.exists?("#{node.bamboo.install_dir}/bamboo.sh") }
end

template "#{node.bamboo.install_dir}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties" do
  mode 00644
end

template "/etc/init/bamboo.conf" do
  mode 00644
end

service "bamboo" do
  provider Chef::Provider::Service::Upstart
  action [:enable, :start]
end
