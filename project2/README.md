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
### 1.1 Upgrading the system

#### Commands Used

``` bash 
sudo apt update && sudo apt upgrade
```
### 1.2 Locating and Installing Node.js

#### Commands Used
 ``` bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

 ```
 ##### Note
 * The command above installs both node and its default package manager NPM


* Verify the installations with the following commands
 ```bash
 node -v
 npm -v
 ```
 **Screenshots:**

 ![Node Installed](screenshots/verification_of_node_installation.png)

### 1.3 Application Code Setup
* Make a directory for your project using the ```mkdir Todo ``` command
* Change into your directory using ``` cd ```
* Initialise your project using ``` npm init ```

### 1.4 Install Express
* Please note, express is a node js framework
* Install it wil npm with the following command
```bash
npm install express
```
* Create an index.js file using
```bash
touch index.js
```
* Install the dotenv module
```bash
npm install dotenv
```
* Open index.js and enter the following commands

```bash

const express = require('express');
require('dotenv').config();

const app = express();

const port = process.env.PORT || 5000;

app.use((req, res, next) => {
res.header("Access-Control-Allow-Origin", "\*");
res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
next();
});

app.use((req, res, next) => {
res.send('Welcome to Express');
});

app.listen(port, () => {
console.log(`Server running on port ${port}`)
}); 

```
* In the same diectory as your index.js run the following command
```bash
noded index.js
```
* If your setup was successful, you should see that your server is running on port 5000

**Screenshot**

 ![Server Running](screenshots/server_running_on_5000.png)

 * In your EC2 security group create a new inbound rule for port 5000

**Screenshot**

![EC2 5000](screenshots/ec2_5000.png)

* Open your web browser and access your server's public ip followed by port 5000

```bash
http://<publicDNS>:5000
```
**Screenshot**
![Welcome to express](screenshots/welcome_to_express.png)

### 1.5 Routes
* Routing refers to how an application’s endpoints (URIs) respond to client requests
* Make a directory called routes open it and create a file called api.js
#### Commands used
```bash
mkdir routes
cd routes
touch api.js
```
* Using an editor open api.js and paste in the following code snippet
```bash
const express = require ('express');
const router = express.Router();

router.get('/todos', (req, res, next) => {

});

router.post('/todos', (req, res, next) => {

});

router.delete('/todos/:id', (req, res, next) => {

})

module.exports = router;
```
### 1.6 Models
* The app uses MongoDB which is Nosql so we need to create a model for structure, validation, business logic and maintainability
* Change back into the todo folder ```cd ..` and install mongoose
```bash
npm install mongoose
```
 * Create a new folder called models, change into that directory and create a file called todo.js
 ```bash
 mkdir model
 cd model
 touch api.js
 ```
* Open api.js and paste in the following code

```bash
const express = require ('express');
const router = express.Router();
const Todo = require('../models/todo');

router.get('/todos', (req, res, next) => {

//this will return all the data, exposing only the id and action field to the client
Todo.find({}, 'action')
.then(data => res.json(data))
.catch(next)
});

router.post('/todos', (req, res, next) => {
if(req.body.action){
Todo.create(req.body)
.then(data => res.json(data))
.catch(next)
}else {
res.json({
error: "The input field is empty"
})
}
});

router.delete('/todos/:id', (req, res, next) => {
Todo.findOneAndDelete({"_id": req.params.id})
.then(data => res.json(data))
.catch(next)
})

module.exports = router;
```

## 2 Mongo Database
* We'll use MongoDB Atlas (formerly mLab) as our cloud database service (DBaaS).
### 2.1 Account Setup
* Sign up at MongoDB Atlas

* Select AWS as cloud provider

* Choose a region near your location

### 2.2 Security Configuration
* Allow access from anywhere (for testing purposes)

* Important: Change auto-deletion time from 6 Hours to 1 Week

### 2.3 Database Creation
* Create a new MongoDB database

* Create collections within your database

### 2.4 Create Environment File
* Create a .env file in your Todo directory:

```bash
touch .env
vi .env
```
### 2.5 Add Database Connection String
Add your MongoDB connection string to the .env file:

```bash
DB = 'mongodb+srv://<username>:<password>@<network-address>/<dbname>?retryWrites=true&w=majority'
Replace the following placeholders:
```

username: Your MongoDB username

password: Your MongoDB password

network-address: Your cluster address

dbname: Your database name

### 2.6 Get Connection String from MongoDB Atlas
* Go to your Cluster overview

* Click "Connect"

* Choose "Connect your application"

* Copy the connection string

* Replace the password and database name in the string

### 2.7 Update index.js File
Replace the entire content of index.js with:
```bash 
const express = require('express');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const routes = require('./routes/api');
const path = require('path');
require('dotenv').config();

const app = express();

const port = process.env.PORT || 5000;

// Connect to the database
mongoose.connect(process.env.DB, { useNewUrlParser: true, useUnifiedTopology: true })
.then(() => console.log(`Database connected successfully`))
.catch(err => console.log(err));

// Since mongoose promise is deprecated, we override it with nodes promise
mongoose.Promise = global.Promise;

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});

app.use(bodyParser.json());

app.use('/api', routes);

app.use((err, req, res, next) => {
  console.log(err);
  next();
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`)
});
```
* Using Vim to Replace File Content:
``` bash
vim index.js
```
### 2.8 Start the Server
```bash
node index.js
```
* Expected Output
* If successful, you should see:

* Database connected successfully

* Server running on port 5000

#### Security Note
* Using environment variables (.env) is a security best practice that separates sensitive configuration data from your application code.

**Screeenshot**
![Database Connected Successful](screenshots/database_connected_successfully.png)

## 3 Testing the Backendsetup
### 3.1 Install Postman
* Download and install Postman

* Learn CRUD operations with Postman
### 3.2  POST Request - Create New Task
* Endpoint: http://<PublicIP-or-PublicDNS>:5000/api/todos

* Headers:

* Content-Type: application/json

* Body (JSON):
```bash
{
  "task": "Your task description"
}
```
**Screenshot**
![Post request](screenshots/post_request.png)

### 3.3 GET Request
* Endpoint: http://<PublicIP-or-PublicDNS>:5000/api/todos
**Screenshot**
![Get request](screenshots/get_request.png)

### 3.4 DELETE Request - Remove Task (Optional)
* Endpoint: http://<PublicIP-or-PublicDNS>:5000/api/todos/<task_id>
**Screenshot**
![Delete request](screenshots/delete_request.png)

## 4 Frontend Creation

### 4.1 Setting Up React Frontend
* Create React Application
```bash
npx create-react-app client
```
* This creates a client folder in your Todo directory with all React code.

### 4.2 Install Development Dependencies
* Install Concurrently - Run multiple commands simultaneously:

``` bash
npm install concurrently --save-dev
```
* Install Nodemon - Auto-restart server on code changes:
``` bash
npm install nodemon --save-dev
```
### 4.3 Update package.json Scripts
* In the main Todo/package.json file, update the scripts section:
```bash
"scripts": {
  "start": "node index.js",
  "start-watch": "nodemon index.js",
  "dev": "concurrently \"npm run start-watch\" \"cd client && npm start\""
}
```

### 4.4 Configure Proxy for API Calls
* Navigate to client directory:

```bash
cd client
```
* Open client/package.json and add:

``` json
"proxy": "http://localhost:5000"
```
* Purpose: This allows React to proxy API requests to your backend server, so you can call /api/todos instead of http://localhost:5000/api/todos

### 4.5 Start Development Server
* From the main Todo directory:

```bash
npm run dev
```
* Expected Result
* Application opens at localhost:3000

* Backend runs on localhost:5000

* Frontend automatically proxies API requests to backend

#### Security Note
* To access from the internet:

* Open TCP port 3000 in EC2 Security Group

* Add inbound rule for port 3000

* This setup allows you to develop both frontend and backend simultaneously with hot reloading for both servers.

## 5 Creating React Components
### 5.1 Building React Components
* Directory Structure Setup
```bash
cd client/src
mkdir components
cd components
```
* Create Component Files
```bash
touch Input.js ListTodo.js Todo.js
```
* 1. Input Component (Input.js)
```bash
import React, { Component } from 'react';
import axios from 'axios';

class Input extends Component {
  state = { action: "" }

  addTodo = () => {
    const task = { action: this.state.action }
    
    if(task.action && task.action.length > 0){
      axios.post('/api/todos', task)
        .then(res => {
          if(res.data){
            this.props.getTodos();
            this.setState({action: ""})
          }
        })
        .catch(err => console.log(err))
    } else {
      console.log('input field required')
    }
  }

  handleChange = (e) => {
    this.setState({ action: e.target.value })
  }

  render() {
    return (
      <div>
        <input type="text" onChange={this.handleChange} value={this.state.action} />
        <button onClick={this.addTodo}>add todo</button>
      </div>
    )
  }
}

export default Input
```
* 2. ListTodo Component (ListTodo.js)
```bash
import React from 'react';

const ListTodo = ({ todos, deleteTodo }) => {
  return (
    <ul>
      {todos && todos.length > 0 ? (
        todos.map(todo => {
          return (
            <li key={todo._id} onClick={() => deleteTodo(todo._id)}>
              {todo.action}
            </li>
          )
        })
      ) : (
        <li>No todo(s) left</li>
      )}
    </ul>
  )
}

export default ListTodo
```
* 3. Todo Component (Todo.js)
```bash
import React, {Component} from 'react';
import axios from 'axios';
import Input from './Input';
import ListTodo from './ListTodo';

class Todo extends Component {
  state = { todos: [] }

  componentDidMount() {
    this.getTodos();
  }

  getTodos = () => {
    axios.get('/api/todos')
      .then(res => {
        if(res.data){
          this.setState({ todos: res.data })
        }
      })
      .catch(err => console.log(err))
  }

  deleteTodo = (id) => {
    axios.delete(`/api/todos/${id}`)
      .then(res => {
        if(res.data){
          this.getTodos()
        }
      })
      .catch(err => console.log(err))
  }

  render() {
    return(
      <div>
        <h1>My Todo(s)</h1>
        <Input getTodos={this.getTodos}/>
        <ListTodo todos={this.state.todos} deleteTodo={this.deleteTodo}/>
      </div>
    )
  }
}

export default Todo;
```

* Install Axios
```bash
cd ../..
npm install axios
cd src/components
```
* Update App.js
```bash 
import React from 'react';
import Todo from './components/Todo';
import './App.css';

const App = () => {
  return (
    <div className="App">
      <Todo />
    </div>
  );
}

export default App;
```
* Update App.css
```bash
.App {
text-align: center;
font-size: calc(10px + 2vmin);
width: 60%;
margin-left: auto;
margin-right: auto;
}

input {
height: 40px;
width: 50%;
border: none;
border-bottom: 2px #101113 solid;
background: none;
font-size: 1.5rem;
color: #787a80;
}

input:focus {
outline: none;
}

button {
width: 25%;
height: 45px;
border: none;
margin-left: 10px;
font-size: 25px;
background: #101113;
border-radius: 5px;
color: #787a80;
cursor: pointer;
}

button:focus {
outline: none;
}

ul {
list-style: none;
text-align: left;
padding: 15px;
background: #171a1f;
border-radius: 5px;
}

li {
padding: 15px;
font-size: 1.5rem;
margin-bottom: 15px;
background: #282c34;
border-radius: 5px;
overflow-wrap: break-word;
cursor: pointer;
}

@media only screen and (min-width: 300px) {
.App {
width: 80%;
}

input {
width: 100%
}

button {
width: 100%;
margin-top: 15px;
margin-left: 0;
}
}

@media only screen and (min-width: 640px) {
.App {
width: 60%;
}

input {
width: 50%;
}

button {
width: 30%;
margin-left: 10px;
margin-top: 0;
}
}
```
* Update index.css
```bash 
body {
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Oxygen",
    "Ubuntu", "Cantarell", "Fira Sans", "Droid Sans", "Helvetica Neue",
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  box-sizing: border-box;
  background-color: #282c34;
  color: #787a80;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, "Courier New",
    monospace;
}
```
* Start Application
```bash
cd ../..
npm run dev
```
* The app should now be fully functional with a modern React interface connected to your backend API!

**Screenshot**
![Working App](screenshots/react_app_working.png)