const path = require('path');

if (config.devServer) {
    config.devServer.server = {
        type: 'https',
    }

    config.devServer.static = [
        { directory: path.join(__dirname, 'kotlin') },
        { directory: "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI" },
        { directory: "C:\\MyFiles\\ffxi\\audio\\output" },
    ]
}