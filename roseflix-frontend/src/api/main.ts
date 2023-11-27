import axios from 'axios';
import { ROUTES } from '../constants/routes';

let connectionstring = `${process.env.REACT_APP_SERVER_URL}/api/v1`
console.log("the string is: ",connectionstring)
const instance = axios.create({
	// prod var: baseURL: `${process.env.REACT_APP_SERVER_URL}/api/v1`
	baseURL: connectionstring
});

instance.interceptors.request.use((req) => {
	if (req.url !== ROUTES.HOME.path && req.url !== ROUTES.SIGNIN.path && req.url !== ROUTES.SIGNUP.path) {
		req.headers = { ...req.headers, Authorization: `Basic ${localStorage.getItem('roseflix-auth')}` };
	}
	return req;
});

export default instance;
