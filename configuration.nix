{
    imports = [
        ./config
        ./config/service/wireguard
    ];

    homelab = {
        system = {
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";
        };
    };
}
