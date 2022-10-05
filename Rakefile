# frozen_string_literal: true

require_relative './belposttrackerbot'

# Rubocop is only installed in dev environment
begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
end

# RSpec is only installed in dev environment
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
rescue LoadError
end

namespace :belpost do
  namespace :db do
    task :initdb do
      ActiveRecord::Base.establish_connection Belpost::Config.options['database']

      ActiveRecord::Tasks::DatabaseTasks.db_dir = '.'
      ActiveRecord::Tasks::DatabaseTasks.migrations_paths = 'db/'

      ActiveRecord::Migrator.migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths
    end

    desc 'Retrieves the current schema version number'
    task version: :initdb do
      db_name = ActiveRecord::Base.connection.try(:current_database) || Belpost::Config.options['database'][:database]
      puts "Current version of `#{db_name}`: #{ActiveRecord::Base.connection.migration_context.current_version}"
    end

    desc 'Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog).'
    task migrate: :initdb do
      ActiveRecord::Tasks::DatabaseTasks.migrate
    end

    namespace :migrate do
      desc 'Display status of migrations'
      task status: :initdb do
        abort 'Schema migrations table does not exist yet.' unless ActiveRecord::SchemaMigration.table_exists?

        puts "\ndatabase: #{ActiveRecord::Base.connection_config[:database]}\n\n"
        puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
        puts '-' * 50
        ActiveRecord::Base.connection.migration_context.migrations_status.each do |status, version, name|
          puts "#{status.center(8)}  #{version.ljust(14)}  #{name}"
        end
        puts
      end
    end

    desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
    task rollback: :initdb do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      ActiveRecord::Base.connection.migration_context.rollback(step)
    end
  end
end

task default: ['rubocop', 'belpost:db:migrate', 'spec']
