<?php

/*
 *  sample.php - sample usage of rhubarb php client,
 *  e.g. as an AJAX/cgi responder
 *
 *  
 *  "http://<url to this file>/sample.php"
 *  
 *  to retrieve the value of ultimateAnswer, or
 *  
 *  "http://<url to this file>/sample.php?LUE=54"
 *
 *  to request setting the value of ultimateAnswer to 54, and
 *  obtain the final value as a response
 *
 *  
 *  Copyright (c) 2011 Daniel T. Swain
 *  See the file license.txt for copying permissions
 *
 */

/* The address and port must match the server's config.
 * If you're running the server and the php script on the same machine,
 * (even if you're running accessing it via http), then the address should
 * be 127.0.0.1 or localhost. */
$rhubarb_address = '127.0.0.1';
$rhubarb_port = 1234;

/* load the class file */
require_once('clients/rhubarbClient.php');

/* create the client object */
$client = new rhubarbClient();

/* attempt to connect to the server. */
if(!$client->connect($server_address, $server_port))
{
    /* gracefully handle if the client fails to connect */
    echo "<span>Error connecting to rhubarb server at " . $rhubarb_address;
    echo ":" . $server_port "</span>";
    die();
}

/* see if the LUE parameter was passed in the CGI request,
 * set $value to an empty string otherwise */ 
$value = (isset($_GET["LUE"]) ? $_GET["LUE"] : "");

/* we'll se the message appropriately depending upon $value */
$message = "";

if(!(strlen($value)))
{
    /* set the message to just query the value */
    $message = "get ultimateAnswer";
}
else
{
    /* set the message for a request to set the value */
    $message = "set ultimateAnswer " . $value;
}

/* send the message to the server and report the response */
echo $client->sendMessage($message);

?>