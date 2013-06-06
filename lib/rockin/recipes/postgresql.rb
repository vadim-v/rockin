Capistrano::Configuration.instance(:must_exist).load do
  set_default(:postgresql_host, "localhost")
  set_default(:postgresql_user) { application }
  set_default(:postgresql_password) { Capistrano::CLI.password_prompt "PostgreSQL Password: " }
  set_default(:postgresql_database) { "#{application}_production" }

  namespace :postgresql do
    desc "Install the latest stable release of PostgreSQL."
    task :install, roles: :db, only: {primary: true} do
      run "#{sudo} apt-get -y install postgresql libpq-dev"
    end
    if database.eql?("postgresql")
      after "deploy:install", "postgresql:install"
    end

    desc "Create a database for this application."
    task :create_database, roles: :db, only: {primary: true} do
      run %Q{#{sudo} -u postgres psql -c "create user #{postgresql_user} with password '#{postgresql_password}';"}
      run %Q{#{sudo} -u postgres psql -c "create database #{postgresql_database} owner #{postgresql_user} encoding = 'UTF8';"}
    end
    if database.eql?("postgresql")
      after "deploy:setup", "postgresql:create_database"
    end

    desc "Generate the database.yml configuration file."
    task :setup, roles: :app do
      run "mkdir -p #{shared_path}/config"
      template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
    end
    if database.eql?("postgresql")
      after "deploy:setup", "postgresql:setup"
    end

    desc "Symlink the database.yml file into latest release"
    task :symlink, roles: :app do
      run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    end
    if database.eql?("postgresql")
      after "deploy:finalize_update", "postgresql:symlink"
    end
  end
end
