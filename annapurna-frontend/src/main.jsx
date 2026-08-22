globalThis.global = globalThis;
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import './index.css'
import App from './App.jsx'

// Lazy load components
import AddDish from './component/MenuPages/addDish.jsx'
import AddCustomer from './component/CustomerPages/addCustomer.jsx'
import Report from './component/Report.jsx'
import OrderSheet from './component/orderSheet.jsx'



createRoot(document.getElementById('root')).render(
  <StrictMode>
    <Router>
      <Routes>
        <Route path="/" element={<App />}>
          <Route index element={<Navigate to="/order-sheet" replace />} />
          <Route path="order-sheet" element={<OrderSheet />} />
          <Route path="add-customer" element={<AddCustomer />} />
          <Route path="report" element={<Report />} />

        </Route>
      </Routes>
    </Router>
  </StrictMode>,
)
