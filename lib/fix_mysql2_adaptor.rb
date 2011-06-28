puts "----------------------------------------------------- loading the patched version -----------------------------------------------------------"

module ActiveRecord
  module ConnectionAdapters
    class Mysql2Adapter

      def query_with_reconnect(sql)
        @connection.query(sql)
      rescue Mysql2::Error => exception
        if exception.message.starts_with? "This connection is still waiting for a result"
          puts "----------------------------------------------------- this is supposed to fix it -----------------------------------------------------------"
          reconnect!
          retry
        end
        raise
      end

      # Executes the SQL statement in the context of this connection.
      def execute(sql, name = nil)
        puts "----------------------------------------------------- using the patched version -----------------------------------------------------------\n#{sql}"
        
        # make sure we carry over any changes to ActiveRecord::Base.default_timezone that have been
        # made since we established the connection
        @connection.query_options[:database_timezone] = ActiveRecord::Base.default_timezone
        if name == :skip_logging
          query_with_reconnect(sql)
        else
          log(sql, name) { query_with_reconnect(sql) }
        end
      rescue ActiveRecord::StatementInvalid => exception
        if exception.message.split(":").first =~ /Packets out of order/
          raise ActiveRecord::StatementInvalid, "'Packets out of order' error was received from the database. Please update your mysql bindings (gem install mysql) and read http://dev.mysql.com/doc/mysql/en/password-hashing.html for more information.  If you're on Windows, use the Instant Rails installer to get the updated mysql bindings."
        else
          raise
        end
      end
    end
  end
end
