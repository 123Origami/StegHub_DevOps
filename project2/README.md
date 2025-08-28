# MERN STACK IMPLEMENTATION
## Project Overview
* This project follows the installation and configuration of MERN stack on a Ubuntu server
* We will also create a basic todo list that enables you to add and remove items from it

## Prerequesties
Before starting this guide, make sure you have:

1. **An AWS Account**  
   - You’ll need access to the [AWS Management Console](https://aws.amazon.com/console/) to create and manage your EC2 instance.  

2. **An EC2 Instance (Ubuntu 22.04 LTS recommended)**  
   - Minimum: t2.micro (Free Tier eligible) with 1 vCPU and 1 GB RAM.  
   - Security group configured to allow:  
     - **SSH** (port 22) — for remote terminal access.  
     - **HTTP** (port 80) — for web traffic.  
     - **HTTPS** (port 443) — optional, for secure web traffic.  

3. **SSH Key Pair**  
   - Downloaded when creating your EC2 instance.  
   - Keep it safe — it’s your login credential.

4. **Basic Terminal Knowledge**  
   - Ability to navigate the terminal and run commands like `cd`, `ls`, `sudo`.  

5. **Local Machine Requirements**  
   - A terminal (Linux/Mac) or **PowerShell**/**WSL** (Windows). (For this project I used both git bash and powershell)  
   - **SSH client** installed (most systems have it by default).  

6. **Text Editor**  
   - [VS Code](https://code.visualstudio.com/) or any preferred editor for editing configuration files. (I was using nano  and Vim on the Ubuntu server and VS code for the MD) 

7. **Stable Internet Connection**  
   - For installing packages and accessing your server remotely.



## 1. Backend Configuration
* Start by upgrading and updating your system with the following commands

''' bash 

sudo apt update && sudo apt upgrade

'''