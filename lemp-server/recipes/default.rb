#
# Cookbook Name:: lemp-server
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
# php5-curl, php5-mysql, php5-gd

app = search("aws_opsworks_app").first
Chef::Log.info("********** The app's short name is '#{app['app_source']['url']}' **********")
Chef::Log.info("********** The app's URL is '#{app['app_source']['url']}' **********")


appdata = app.to_yaml

file '/home/ubuntu/deployment.yml' do
  content appdata
end

file '/root/.ssh/id_rsa' do
 	content "#{app['app_source']['ssh_key']}"
 	mode '600'
end

file "/root/git_wrapper.sh" do
  mode "0755"
  atomic_update true
  content "#!/bin/sh\nexec /usr/bin/ssh -i -o StrictHostKeyChecking=no /root/.ssh/id_rsa \"$@\""
end

directory "#{node[:deployment_path]}" do
   owner "#{node[:nginx_user]}"
   group "#{node[:nginx_group]}"
   mode '0755'
   action :create
end

 deploy 'private_repo' do
  symlink_before_migrate.clear
  create_dirs_before_symlink.clear
  purge_before_symlink.clear
  symlinks.clear
  repo "#{app['app_source']['url']}"
  deploy_to "#{node[:deployment_path]}"
  ssh_wrapper '/root/git_wrapper.sh'
  action :deploy
  user  'root'
end

directory "#{node[:nginx_document_root]}" do
  owner 'www-data'
  group 'www-data'
  mode '0755'
  action :create
end

package 'nginx' do
	action 'install'
end


package "php5" do
  action 'install'
end

package ['php5-common'] do
	action :install
end

package ['php5-cli' ] do
	action :install
end

package ['php5-json'] do
  action :install
end

package ['php5-gd'] do
  action :install
end

package ['php5-curl'] do
	action :install
end


package 'php5-fpm' do
	action :install
end


package ['php5-readline'] do
	action :install
end

package ['php5-mysql'] do
	action :install
end

package 'mysql-client' do
	action :install
end

file '/etc/nginx/sites-enabled/default' do 
  action 'delete'
end

file '/etc/nginx/sites-enabled/000-default' do 
  action 'delete'
end

package ['php5-mysql'] do
	action :install
end

template "/etc/nginx/sites-available/#{node[:nginx_host_name]}.conf" do
  source "serverblock2.erb"	
end

link "/etc/nginx/sites-enabled/#{node[:nginx_host_name]}.conf" do
  to "/etc/nginx/sites-available/#{node[:nginx_host_name]}.conf"
end

service 'nginx' do
	action :restart
end

service 'php5-fpm' do
  action :stop
end
service 'php5-fpm' do
	action :start
end