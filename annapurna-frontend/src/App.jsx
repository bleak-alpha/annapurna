import { Outlet } from 'react-router-dom'
import './App.css'
import Sidebar from './component/Slidebar.jsx'
import Header from './component/header.jsx'
import Footer from './component/footer.jsx'

function App() {
  return (
    <div className="app-shell">
      <Header />

      {/* <div className="layout">
        <Sidebar /> */}
        <div className="main">
          <Outlet />
        {/* </div> */}
      </div>

      <Footer />
    </div>
  )
}

export default App
