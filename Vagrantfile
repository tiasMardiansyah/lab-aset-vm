Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "aset-lab"

  # Choose ONE of the two network options below:

  # Option A — Isolated lab network (safer, recommended for coursework)
  # config.vm.network "private_network", ip: "192.168.56.10"

  # Option B — Bridged to your real LAN (reachable from your own Kali box directly)
  config.vm.network "public_network"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.name = "web-aset-lab-vm"
  end

  config.vm.synced_folder "./app", "/opt/aset-app"
  config.vm.provision "shell", path: "provision.sh"
end