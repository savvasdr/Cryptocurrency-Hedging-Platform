import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

it('renders without crashing', () => {
  const div = document.createElement('div');
  ReactDOM.render(<App />, div);
  ReactDOM.unmountComponentAtNode(div);
});


//////////////////////

import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';
import web3 from './web3';
import iot from './iot';

class App extends Component {
  state = {
    devices: '',
	name1: '',
	name2: ''
  };
  

  async componentDidMount() {
    const devices = await iot.methods.id().call();
    
	
	//const players = await lottery.methods.getPlayers().call();
    //const balance = await web3.eth.getBalance(lottery.options.address);

    this.setState({ devices });
  }
  
  getDevicesID = async () => {
	this.setState(await iot.methods.getUserDevices().call());
  };
  
  getDeviceInfo = async event => {
    event.preventDefault();

	const accounts = await web3.eth.getAccounts();
	
	this.setState({ message: this.state.value })
	
	const test = await iot.methods.getDevice(this.state.value).call();
	
	this.setState({ test });
  

	//this.setState(await iot.methods.getDevice().send({
	//	from: accounts[0],
	//	value: (this.target.value1)
    //}));
  };
  
  addNewDevice = async event => {
    event.preventDefault();

	const accounts = await web3.eth.getAccounts();
	
	this.setState({ message: this.state.value })
	
	const test = await iot.methods.addDevice(this.state.value).call();
	
	this.setState({ message: "Okk" });
  

	//this.setState(await iot.methods.getDevice().send({
	//	from: accounts[0],
	//	value: (this.target.value1)
    //}));
  };
  

  
  render() {

	  
    return (
      <div>
	  <h2>IOT with Blockchain</h2>
	  <p>
		There are <b>{this.state.devices}</b> smart devices connected with the Blockchain.{' '}
		Log in with your Metamask account to add and control your devices.
	  </p>
	  
	  <hr/>
	  
	  <button onClick={this.getDevicesID}>Get the id's of your devices!</button>
	  <h1>{this.state.message}</h1>
	  
	  <hr/>
	  
	  <form onSubmit={this.getDeviceInfo}>
          <h4>View information about a specific device</h4>
          <div>
            <label>Enter your device ID:</label>
            <input
		      name="name1"
			  type="number"
              value={this.state.name1}
              onChange={event => this.setState({ value: event.target.value })}
            />
          </div>
          <button>View info</button>
      </form>
	  
	  
	   <hr/>
	  </div>
	    //<form onSubmit={this.addNewDevice}>
        //  <h4>Add new smart device</h4>
        //  <div>
		//	<p>Enter your device name and it's state. If no state is defined, it will be set a "false".</p>
        //    <label>[ "Device name", true/false ] </label>
        //    <input
		//	  name="name2"
        //      value={this.state.name2}
        //      onChange={event => this.setState({ value: event.target.value })}
       //     />
       //   </div>
       //   <button>Add device</button>
       //  </form>
	  
	  
	  
	  
	  
    );
  }
}

export default App;