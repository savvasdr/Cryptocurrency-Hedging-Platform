import React, {Component}
from 'react';
import './App.css';
import web3 from './web3';
import AutoMatch from './AutoMatch';
import Logic from './Logic';
import Data from './Data';
import Proxy from './Proxy';
import {
	Button,
	Input,
	Item,
	Grid,
	Label,
	Icon
}
from 'semantic-ui-react'
import 'semantic-ui-css/semantic.min.css';


class App extends Component {
  
  state = {
  	haveLatestEthPrice: '',
  	waitForNewStoreOfValueOrder: '',
  	waitForNewIncreasePriceOrder: '',
  	newStoreOfValueOrderAmount: '',
  	newIncreasePriceOrderAmount: '',
  	userStoreOfValueOpenOrdersID: [],
  	userIncreasePriceOpenOrdersID: [],
  	userMatchedOrdersID: [],
  	userStoreOfValueOpenOrdersAmount: [],
  	userIncreasePriceOpenOrdersAmount: [],
  	userMatchedOrdersAmount: [],
  	userMatchedOrdersType: [],
  	userMatchedOrdersEtherPrice: [],
  	cancelOrderWait: '',
  	completeOrderWait: '',
  	ethPrice: ''
  };
  
  async componentDidMount() {
  	// Check for latest ETH price
  	const haveRecentPrice = await Logic.methods.haveRecentETHprice().call();
	
  	if (haveRecentPrice) {
  		this.setState({
  			haveLatestEthPrice: "OKKK! You have a recent Ether/USD price. You can continue..."
  		});
  	} else {
  		this.setState({
  			haveLatestEthPrice: "Ohhh you don't have a recent Ether/USD price. Plese click on 'GET LATEST PRICE' button!!!"
  		});
  	}

  	// Get the latest ETH price
  	const ethPrice = await Logic.methods.getETHUSDprice().call();
  	this.setState({
  		ethPrice
  	});

  	// Get all 'Store of Value' open orders ID's of the user
  	const accounts = await web3.eth.getAccounts();
  	const storeOfValueOpenOrders = await Logic.methods.getUserStoreOfValueOpenOrders().call({
  			from: accounts[0]
  		}).then();
  	var storeOfValueOpenOrdersArray = [];

  	for (var key in storeOfValueOpenOrders) {
  		storeOfValueOpenOrdersArray.push(storeOfValueOpenOrders[key]);
  	}

  	this.setState({
  		userStoreOfValueOpenOrdersID: storeOfValueOpenOrdersArray
  	});

  	// Get all 'Increase price bet' open orders ID's of the user
  	const increasePriceOpenOrders = await Logic.methods.getUserPriceIncreaseOpenOrders().call({
  			from: accounts[0]
  		}).then();
  	var increasePriceOpenOrdersArray = [];

  	for (var key in increasePriceOpenOrders) {
  		increasePriceOpenOrdersArray.push(increasePriceOpenOrders[key]);
  	}

  	this.setState({
  		userIncreasePriceOpenOrdersID: increasePriceOpenOrdersArray
  	});

  	// Get all 'Store of Value' open orders amount of the user
  	var storeOfValueAmountArray = [];
  	for (var key in storeOfValueOpenOrdersArray) {
  		storeOfValueAmountArray.push((await Data.methods.getStoreOfValueAmountByID(storeOfValueOpenOrdersArray[key]).call({
  					from: accounts[0]
  				})) / 10 ** 18);
  	}
  	this.setState({
  		userStoreOfValueOpenOrdersAmount: storeOfValueAmountArray
  	});

  	// Get all 'Increase price bet' open orders amount of the user
  	var increasePriceAmountArray = [];
  	for (var key in increasePriceOpenOrdersArray) {
  		increasePriceAmountArray.push((await Data.methods.getIncreasePriceAmountByID(increasePriceOpenOrdersArray[key]).call({
  					from: accounts[0]
  				})) / 10 ** 18);
  	}
  	this.setState({
  		userIncreasePriceOpenOrdersAmount: increasePriceAmountArray
  	});

  	// Get all 'Matched orders' of the user
  	const matchedOrders = await Logic.methods.getUserMatchedOrders().call({
  			from: accounts[0]
  		}).then();
  	var matchedOrdersArray = [];

  	for (var key in matchedOrders) {
  		matchedOrdersArray.push(matchedOrders[key]);
  	}

  	this.setState({
  		userMatchedOrdersID: matchedOrdersArray
  	});

  	// Get all 'Matched' orders information of the user and convert them to arrays to use map function.
  	var matchedAmountObject = [];
  	var userMatchedOrdersAmount = [];
  	var userMatchedOrdersType = [];
  	var userMatchedOrdersEtherPrice = [];

  	for (var key in matchedOrdersArray) {
  		matchedAmountObject.push((await Data.methods.getMatchedOrderInformationtByID(matchedOrdersArray[key]).call({
  					from: accounts[0]
  				})));
  	}

  	for (var key in matchedAmountObject) {
  		userMatchedOrdersAmount.push(matchedAmountObject[key][0] / 10 ** 18);
  		userMatchedOrdersType.push(matchedAmountObject[key][1]);
  		userMatchedOrdersEtherPrice.push(matchedAmountObject[key][2]);
  	}

  	this.setState({
  		userMatchedOrdersAmount
  	});
  	this.setState({
  		userMatchedOrdersType
  	});
  	this.setState({
  		userMatchedOrdersEtherPrice
  	});
  }
  
  haveRecentETHprice = async() => {
  	const haveRecentPrice = await Logic.methods.haveRecentETHprice().call();

  	if (haveRecentPrice) {
  		this.setState({
  			haveLatestEthPrice: "OKKK! You have a recent Ether/USD price. You can continue..."
  		});
  	} else {
  		this.setState({
  			haveLatestEthPrice: "Ohhh you don't have a recent Ether/USD price. Plese click on 'GET LATEST PRICE' button!!!"
  		});
  	}

  };

  updatePrice = async event => {
  	event.preventDefault();

  	const accounts = await web3.eth.getAccounts();
  	const queryFee = await Logic.methods.estimateGas().call();

  	this.setState({
  		haveLatestEthPrice:  < div dangerouslySetInnerHTML = { {
  				__html: '<div class="ui segment"><div class="ui active transition visible dimmer"><div class="content"><div class="ui loader"></div></div></div><img src="https://react.semantic-ui.com/images/wireframe/short-paragraph.png" class="ui image"/></div>'
  			}
  		}
  		/> });

  			await Logic.methods.updatePrice().send({
  				from: accounts[0],
  				value: queryFee
  			}).then(function(result){}).catch(error => {this.setState({haveLatestEthPrice: "Please try again!"});})


		// The function call was completed.But we have also to wait for the callback function .
  		function timer(ms) {
  			return new Promise(res => setTimeout(res, ms));
  		}

  		async function waitForNewPrice() {
  			var haveLatestEthPrice = await Logic.methods.haveRecentETHprice().call();
  			while (!haveLatestEthPrice) {
  				haveLatestEthPrice = await Logic.methods.haveRecentETHprice().call();
  				await timer(3000);
  			}
  		}

  		await waitForNewPrice();

  		this.setState({
  			haveLatestEthPrice: "OKKK! You have a recent Ether/USD price. You can continue..."
  		});

  };

  	addNewStoreOfValueOrder = async event => {
  		event.preventDefault();

  		const accounts = await web3.eth.getAccounts();

  		this.setState({
  			waitForNewStoreOfValueOrder:  < div dangerouslySetInnerHTML = { {
  					__html: '<div class="ui segment"><div class="ui active transition visible dimmer"><div class="content"><div class="ui loader"></div></div></div><img src="https://react.semantic-ui.com/images/wireframe/short-paragraph.png" class="ui image"/></div>'
  				}
  			}
  			/> });

  				await Logic.methods.addNewOrder(true).send({
  					from: accounts[0],
  					value: web3.utils.toWei(this.state.newStoreOfValueOrderAmount, 'ether')
  				}).then(function(result){}).catch(error => {this.setState({waitForNewStoreOfValueOrder: "Please try again!"});})

  			    this.setState({ waitForNewStoreOfValueOrder: "Refresh the browser..." });

  			  };

  			  addNewIncreaseValueOrder = async event => {
  				event.preventDefault();

  			    const accounts = await web3.eth.getAccounts();

  				this.setState({ waitForNewIncreasePriceOrder: <div dangerouslySetInnerHTML={{ __html: '<div class="ui segment"><div class="ui active transition visible dimmer"><div class="content"><div class="ui loader"></div >  <  / div >  <  / div >  < img src = "https://react.semantic-ui.com/images/wireframe/short-paragraph.png" class = "ui image" /  >  <  / div > ' }} /> });

  					await Logic.methods.addNewOrder(false).send({
  						from: accounts[0],
  						value: web3.utils.toWei(this.state.newIncreasePriceOrderAmount, ' ether ')
  					}).then(function(result){}).catch(error => {this.setState({waitForNewIncreasePriceOrder: "Please try again!"});})

  				    this.setState({ waitForNewIncreasePriceOrder: "Refresh the browser..." });

  				};

	displayStoreOfValueOrders = () => 
	this.state.userStoreOfValueOpenOrdersID.map((el, i) => (
      <div key={`${el}-${this.state.userStoreOfValueOpenOrdersID[i]}`}>
		<Grid>
		<Grid.Column width={8}>
		<Item.Group divided>
			<Item>
				<Item.Content>
					<Item.Header as='a'>"Store of value" order</Item.Header>
					<Item.Extra>
						<Button negative primary floated='right' onClick={ async event => {
																				event.preventDefault();
																				const accounts = await web3.eth.getAccounts();
																				this.setState({ cancelOrderWait: <div dangerouslySetInnerHTML={{ __html: '<div class="ui segment"><div class="ui active transition visible dimmer"><div class="content"><div class="ui loader"></div></div></div><img src="https://react.semantic-ui.com/images/wireframe/short-paragraph.png" class="ui image"/></div>' }} /> });
																				await Logic.methods.cancelOpenOrder(this.state.userStoreOfValueOpenOrdersID[i],true).send({from: accounts[0]}).then(function(result){}).catch(error => {this.setState({cancelOrderWait: "Please try again!"});})
																				this.setState({ cancelOrderWait: "Your order has been canceled..." });
																			}}>
							Cancel
							<Icon name='right chevron' />
						</Button>
						<Label>{this.state.userStoreOfValueOpenOrdersAmount[i]} Ether</Label>
					</Item.Extra>
				</Item.Content>
			</Item>
		</Item.Group>
		</Grid.Column>
		<Grid.Column width={8}>
		</Grid.Column>
		</Grid>
		<br/>
      </div>
    ));

  displayIncreasePriceOrders = () => 
	this.state.userIncreasePriceOpenOrdersID.map((el, i) => (
      <div key={`${el}-${this.state.userIncreasePriceOpenOrdersID[i]}`}>
        <Grid>
		<Grid.Column width={8}>
		<Item.Group divided>
			<Item>
				<Item.Content>
					<Item.Header as='a'>"Store of value" order</Item.Header>
					<Item.Extra>
						<Button negative primary floated='right' onClick={ async event => {
																				event.preventDefault();
																				const accounts = await web3.eth.getAccounts();
																				this.setState({ cancelOrderWait: <div dangerouslySetInnerHTML={{ __html: '<div class="ui segment"><div class="ui active transition visible dimmer"><div class="content"><div class="ui loader"></div></div></div><img src="https://react.semantic-ui.com/images/wireframe/short-paragraph.png" class="ui image"/></div>' }} /> });
																				await Logic.methods.cancelOpenOrder(this.state.userIncreasePriceOpenOrdersID[i],false).send({from: accounts[0]}).then(function(result){}).catch(error => {this.setState({cancelOrderWait: "Please try again!"});})
																				this.setState({ cancelOrderWait: "Your order has been canceled..." });
																			}}>
							Cancel
							<Icon name='right chevron' />
						</Button>
						<Label>{this.state.userIncreasePriceOpenOrdersAmount[i]} Ether</Label>
					</Item.Extra>
				</Item.Content>
			</Item>
		</Item.Group>
		</Grid.Column>
		<Grid.Column width={8}>
		</Grid.Column>
		</Grid>
		<br/>
      </div>
    ));
  

  displayMatchedOrders = () => 
	this.state.userMatchedOrdersID.map((el, i) => ( 
      <div key={`${el}-${this.state.userMatchedOrdersID[i]}`}>
        <Grid>
		<Grid.Column width={8}>
		<Item.Group divided>
			<Item>
				<Item.Content>
					<Item.Header as='a'>{String(this.state.userMatchedOrdersType[i]) === "true" ? "MATCHED ORDER:  Store of Value" : "MATCHED ORDER:  Price Increase Bet"}</Item.Header>
					<Item.Meta>Old Ether price: {this.state.userMatchedOrdersEtherPrice[i]}<br/>
					</Item.Meta>
					<Item.Extra>
						<Button positive primary floated='right' onClick={ async event => {
																				event.preventDefault();
																				const accounts = await web3.eth.getAccounts();
																				this.setState({ completeOrderWait: <div dangerouslySetInnerHTML={{ __html: '<div class="ui segment"><div class="ui active transition visible dimmer"><div class="content"><div class="ui loader"></div></div></div><img src="https://react.semantic-ui.com/images/wireframe/short-paragraph.png" class="ui image"/></div>' }} /> });
																				await Logic.methods.completedOrder(this.state.userMatchedOrdersID[i]).send({from: accounts[0]}).then(function(result){}).catch(error => {this.setState({cancelOrderWait: "Please try again!"});})
																				this.setState({ completeOrderWait: "Your order has been completed..." });
																			}}>
							Complete
							<Icon name='right chevron' />
						</Button>
						<Label>{this.state.userMatchedOrdersAmount[i]} Ether</Label>
					</Item.Extra>
				</Item.Content>
			</Item>
		</Item.Group>
		</Grid.Column>
		<Grid.Column width={8}>
		</Grid.Column>
		</Grid>
		<br/>
      </div>
    ));

  render() {

	  
   return (
    <div class="row">
	
     <div class="column"> 
	 <img src="https://www.aueb.gr/newopa/icons/menu/logo_opa.png" class="ui medium image"/>
	 <h1>Decentralized "Store of Value" platform for Ethereum</h1>	
	  <p>		
		For educational purposes only... 
		Be sure you are connected to your Metamask account <i>(Rinkeby test network)</i>.
	  </p>
	  
	  <hr/>
		
		<i><h2>Your Open Orders</h2></i>

		<hr/>
		{this.state.cancelOrderWait}
		{this.displayStoreOfValueOrders()}
		{this.displayIncreasePriceOrders()}
		<hr/>

		<i><h2>Your Matched Orders</h2></i>

		<hr/>
		{this.state.completeOrderWait}
		{this.displayMatchedOrders()}
		<hr/>
		<br/><br/>
	</div>

	<div class="column"> 
	  
	  <hr/>
		<h4><i aria-hidden="true" class="hand point right icon"></i> BEFORE ADD, COMPLETE OR CANCEL YOUR ORDER</h4>
          <div>
			<p>Make sure that you have received the latest Ether price before making any transaction.,<br/>
			otherwise you won't be able to complete it.</p>
            
			<button onClick={this.haveRecentETHprice} class="ui button">Check again</button>
			<button onClick={this.updatePrice} class="ui active button">GET LATEST PRICE</button>
			<Button color='orange' content='/ ETH price' icon='dollar' label={{ basic: true, color: 'orange', pointing: 'right', content: this.state.ethPrice }} labelPosition='right'/>
			
			<h5>{this.state.haveLatestEthPrice}</h5>
          </div>   
       	  <hr/>
	  
	  <form onSubmit={this.addNewStoreOfValueOrder}>
		  <h2><i aria-hidden="true" class="money icon"></i> Keep your value stable!</h2>
          <div>
			<p>Store the value of your Ether. Insert the amount you want to keep stable.</p>
            <Input 
				label='ETHER' 
				placeholder='At least 0.001' 
				value={this.state.newStoreOfValueOrderAmount}
				onChange={event => this.setState({ newStoreOfValueOrderAmount: event.target.value })}
            />			
			<br/> <br/>
			<button class="ui active button">ADD ORDER</button>
			<br/> <br/>
			<b><h3>{this.state.waitForNewStoreOfValueOrder}</h3></b>
          </div>   
      </form>
	  
	  <hr/>
	  
	  <form onSubmit={this.addNewIncreaseValueOrder}>
		  <h2><i aria-hidden="true" class="chart line icon"></i> Increase your value!</h2>
          <div>
			<p>You can bet on Ether price increase and multiply your value.</p>
            
			<Input 
				label='ETHER' 
				placeholder='At least 0.001' 
				value={this.state.newIncreasePriceOrderAmount}
				onChange={event => this.setState({ newIncreasePriceOrderAmount: event.target.value })}
            />
			
			<br/> <br/>
			
			<button class="ui active button">ADD ORDER</button>
			<br/> <br/>
			<b><h3>{this.state.waitForNewIncreasePriceOrder}</h3></b>
			
          </div>   
      </form>
	  
	  <hr/>
	  
	 </div>	 

    </div>	   
	  
    );
  }
}
		
export default App;