{
    imports = [
        # System
        ./config/system/locale
        ./config/system/user
        ./config/system/misc

        # Services
        ./config/service/wireguard
    ];

    homelab = {
        system = {
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";
        };
    };
}
