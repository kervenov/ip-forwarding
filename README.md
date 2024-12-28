<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IP Forwarding</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
        }
        h1, h2 {
            color: #333;
        }
        code {
            background-color: #f4f4f4;
            padding: 2px 4px;
            border-radius: 4px;
            font-family: Consolas, monospace;
        }
        pre {
            background-color: #f4f4f4;
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <h1>IP Forwarding</h1>

    <h2>How It Works</h2>
    <p><strong>Request Path:</strong></p>
    <pre>Client => Routing VPS => Main VPS</pre>
    <p>All client requests are forwarded through the Routing VPS to the Main VPS.</p>

    <p><strong>Response Path:</strong></p>
    <pre>Main VPS => Routing VPS => Client</pre>
    <p>Responses are dynamically routed back through the same Routing VPS that forwarded the request.</p>

    <p>This ensures that the Main VPS remains anonymous, and all traffic appears to originate from the Routing VPS.</p>

    <h2>Setup Instructions</h2>
    <p>Run the following commands to set up the scripts:</p>

    <h3>Routing VPS</h3>
    <pre>
wget https://raw.githubusercontent.com/kervenov/ip-forwarding/main/routing-vps-setup.sh
chmod +x routing-vps-setup.sh
    </pre>

    <h3>Main VPS</h3>
    <pre>
wget https://raw.githubusercontent.com/kervenov/ip-forwarding/main/main-vps-setup.sh
chmod +x main-vps-setup.sh
    </pre>
</body>
</html>
