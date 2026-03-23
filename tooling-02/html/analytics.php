<?php
    include('db_conn.php');
    include('logout_popup.php');

    session_start();

    if(!isset($_SESSION['sess_user'])) {
        header ("Location: login.php");
    }
?>

<!DOCTYPE html>
<html>
<head>
    <title>Analytics Dashboard</title>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" type="text/css" href="css/dashboard.css">
    <link href='https://fonts.googleapis.com/css?family=IBM Plex Mono' rel='stylesheet'>

</head>
<body>
    <div class="container-fluid dashboard-content">
        <div class="row">
            <div class="col-md-2 sidebar">
                <div class="logo">
                    <img class="logo-img" src="images/StegHub.png" alt="" >
                </div>
                <div class="sidebar-menus">
                    <ul>
                        <li ><a href="home.php"><img src="images/dashboard.png"><span class="menu-title">Dashboard</span></a></li>
                        <li><a href="environment.php"><img src="images/environment.png"><span class="menu-title">Environment</span></a></li>
                        <li><a href="dev_tools.php"><img src="images/tools.png"><span class="menu-title">Devops Tools</span></a></li>
                        <li class="active"><a href="analytics.php"><img src="images/analytics.png"><span class="menu-title">Analytics</span></a></li>
                        <li><a  onclick="popupOpen();"><img src="images/logout.png"><span class="menu-title">Log Out</span></a></li>
                    </ul>
                </div>
            </div>
            <div class="col-md-10 main-content">
                <div class="titles">
                    <h4>Analytics Dashboard</h4>
                </div>
                <div class="inner-content">

                    <h3>User Information</h3>
                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>Username</th>
                                <th>Email</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                                $user_sql = "SELECT username, email FROM user";
                                $user_result = mysqli_query($conn, $user_sql);

                                if (mysqli_num_rows($user_result) > 0) {
                                    while($user_row = mysqli_fetch_assoc($user_result)) {
                                        echo "<tr>";
                                        echo "<td>" . $user_row['username'] . "</td>";
                                        echo "<td>" . $user_row['email'] . "</td>";
                                        echo "</tr>";
                                    }
                                } else {
                                    echo "<tr><td colspan='2'>No users found</td></tr>";
                                }
                            ?>
                        </tbody>
                    </table>

                    <h3>Environment Details</h3>
                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>Environment Type</th>
                                <th>Environment Name</th>
                                <th>IP Address</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                                $environment_sql = "SELECT environment_type, environment_name, ip_address FROM environments";
                                $environment_result = mysqli_query($conn, $environment_sql);

                                if (mysqli_num_rows($environment_result) > 0) {
                                    while($environment_row = mysqli_fetch_assoc($environment_result)) {
                                        echo "<tr>";
                                        echo "<td>" . $environment_row['environment_type'] . "</td>";
                                        echo "<td>" . $environment_row['environment_name'] . "</td>";
                                        echo "<td>" . $environment_row['ip_address'] . "</td>";
                                        echo "</tr>";
                                    }
                                } else {
                                    echo "<tr><td colspan='3'>No environments found</td></tr>";
                                }
                            ?>
                        </tbody>
                    </table>

                    <h3>Tool Information</h3>
                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>Tool Name</th>
                                <th>Tool Type</th>
                                <th>URL</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                                $tool_sql = "SELECT tool_name, tool_type, url FROM tools";
                                $tool_result = mysqli_query($conn, $tool_sql);

                                if (mysqli_num_rows($tool_result) > 0) {
                                    while($tool_row = mysqli_fetch_assoc($tool_result)) {
                                        echo "<tr>";
                                        echo "<td>" . $tool_row['tool_name'] . "</td>";
                                        echo "<td>" . $tool_row['tool_type'] . "</td>";
                                        echo "<td>" . $tool_row['url'] . "</td>";
                                        echo "</tr>";
                                    }
                                } else {
                                    echo "<tr><td colspan='3'>No tools found</td></tr>";
                                }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

</body>
</html>