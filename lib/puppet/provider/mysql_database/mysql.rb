Puppet::Type.type(:mysql_database).provide(:mysql) do
  desc 'Manages MySQL databases.'

  commands :mysql => 'mysql'

  def self.defaults_file
    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
      "--defaults-file=#{Facter.value(:root_home)}/.my.cnf"
    else
      nil
    end
  end

  def defaults_file
    self.class.defaults_file
  end

  def self.instances
    mysql([defaults_file, '-NBe', 'show databases'].compact).split("\n").collect do |name|
      attributes = {}
      mysql([defaults_file, '-NBe', 'show variables like "%_database"', name].compact).split("\n").each do |line|
        k,v = line.split(/\s/)
        attributes[k] = v
      end
      new(:name    => name,
          :ensure  => :present,
          :charset => attributes['character_set_database'],
          :collate => attributes['collation_database']
         )
    end
  end

  # We iterate over each mysql_database entry in the catalog and compare it against
  # the contents of the property_hash generated by self.instances
  def self.prefetch(resources)
    databases = instances
    resources.keys.each do |database|
      if provider = databases.find { |db| db.name == database }
        resources[database].provider = provider
      end
    end
  end

  def create
    mysql([defaults_file, '-NBe', "create database `#{@resource[:name]}` character set #{@resource[:charset]}"].compact)

    @property_hash[:ensure]  = :present
    @property_hash[:charset] = @resource[:charset]
    @property_hash[:collate] = @resource[:collate]

    exists? ? (return true) : (return false)
  end

  def destroy
    mysql([defaults_file, '-NBe', "drop database `#{@resource[:name]}`"].compact)

    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  def exists?
    @property_hash[:ensure] == :present || false
  end

  mk_resource_methods

  def charset=(value)
    mysql([defaults_file, '-NBe', "alter database `#{resource[:name]}` CHARACTER SET #{value}"].compact)
    @property_hash[:charset] = value
    charset == value ? (return true) : (return false)
  end

  def collate=(value)
    mysql([defaults_file, '-NBe', "alter database `#{resource[:name]}` COLLATE #{value}"].compact)
    @property_hash[:collate] = value
    collate == value ? (return true) : (return false)
  end

end
