# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"

    config.vm.provision "shell", path: "provision.sh"

    config.vm.provider "virtualbox" do |vb, override|
        vb.customize ["modifyvm", :id, "--memory", "1024"]
    end

		# Forward a port from the guest to the host, which allows for outside
		# computers to access the VM, whereas host only networking does not.
		config.vm.network "forwarded_port", guest: 8888, host: 8888
    config.vm.synced_folder ".", "/home/vagrant/host"
end
