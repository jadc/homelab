{
    imports = [
        ./config/service/wireguard
    ];

    homelab = {
        system = {
            user = "main";
            group = "main";
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";
        };
    };
}
