{
    imports = [
        # System
        ./config/system/locale
        ./config/system/misc
        ./config/system/networkmanager
        ./config/system/systemd-boot
        ./config/system/tlp
        ./config/system/user

        # Services
        ./config/service/ssh
        ./config/service/wireguard
    ];

    homelab = {
        system = {
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";
        };
    };
}
