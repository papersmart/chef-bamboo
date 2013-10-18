include_recipe 'apt'
include_recipe 'java'

cache_path = Chef::Config[:file_cache_path]
tarball_path = "#{cache_path}/#{File.basename(node.bamboo.download_url)}"

user "bamboo" do
  action :create
  supports :manage_home => true
  system true
  shell "/bin/false"
  home node.bamboo.home
end

directory File.join(node.bamboo.bamboo_home) do
  mode 00755
  owner "bamboo"
  group "bamboo"
end

directory node.bamboo.install_dir do
  action :create
  recursive true
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
  cwd node.bamboo.install_dir
  code <<-EOS
    tar -xvzf #{tarball_path} --strip 1
    chown -R bamboo:bamboo .
  EOS
  not_if { ::File.exists?("#{node.bamboo.install_dir}/bamboo.sh") }
end

template "#{node.bamboo.install_dir}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties" do
  mode 00644
end

template "#{node.bamboo.install_dir}/bin/setenv.sh" do
  mode 00755
end

template "/etc/init/bamboo.conf" do
  mode 00644
end

service "bamboo" do
  provider Chef::Provider::Service::Upstart
  action [:enable, :start]
end
