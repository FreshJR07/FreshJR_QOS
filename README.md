# FreshJR QOS - Modification Script for AdaptiveQOS on Asus Routers

This script has been tested on ASUS AC-68U, running RMerlin FW 384.4, using Adaptive QOS with Manual Bandwidth Settings

## Quick Overview:

-- Script Changes Unidentified Packet QOS destination from "Default" Traffic Container (Category7) into user definable (in WebUI) "Others" Traffic Container

-- Script Changes Minimum Guaranteed Bandwidth per QOS category from 128Kbit into user defined percentages upload and download.

-- Script allows for custom QOS rules 

-- Script allows for redirection of existing identified traffic

## Full Overview:

See <a href="https://www.snbforums.com/threads/release-freshjr-adaptive-qos-improvements-custom-rules-and-inner-workings.36836/" rel="nofollow">SmallNetBuilder</a> for more information & discussion

## Installation:

In your SSH Client:

``` curl "https://raw.githubusercontent.com/FreshJR07/FreshJR_QOS/master/FreshJR_QOS.sh" -o /jffs/scripts/FreshJR_QOS --create-dirs && sh /jffs/scripts/FreshJR_QOS -install ```

## Uninstall:

In your SSH Client:

``` /jffs/scripts/FreshJR_QOS -uninstall ```
