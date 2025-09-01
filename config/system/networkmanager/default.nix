{
    # Enable networking
    networking.networkmanager.enable = true;

    # Allow root to configure network settings
    users.users.root.extraGroups = [ "networkmanager" ];
}
