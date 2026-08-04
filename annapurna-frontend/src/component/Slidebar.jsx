import { useState } from "react";
import { useNavigate } from "react-router-dom";

function Sidebar() {
  const navigate = useNavigate();
  const [isCustomerDropdownOpen, setIsCustomerDropdownOpen] = useState(false);
  const [isMenuDropdownOpen, setIsMenuDropdownOpen] = useState(false);
  const [isReportDropdownOpen, setIsReportDropdownOpen] = useState(false);
  const [isOrderDropdownOpen, setIsOrderDropdownOpen] = useState(false);
  const [isPaymentDropdownOpen, setIsPaymentDropdownOpen] = useState(false);

  const handleReportClick = (reportType) => {
    navigate("/report");
    localStorage.setItem("reportType", reportType);
    setIsReportDropdownOpen(false);
  };

  return (
    <div className="sidebar">


      {/* Customer Dropdown */}
      <div className="nav-item-dropdown">
        <div
          className="nav-item customer-header"
          onClick={() =>
            setIsCustomerDropdownOpen(!isCustomerDropdownOpen)
          }
        >
          Customer
          <span
            className={`dropdown-arrow ${
              isCustomerDropdownOpen ? "open" : ""
            }`}
          >
          </span>
        </div>

        {isCustomerDropdownOpen && (
          <div className="dropdown-menu">
            <div
              className="dropdown-item"
              onClick={() => navigate("/add-customer")}
            >
              Add Customer
            </div>

            <div
              className="dropdown-item"
              onClick={() => navigate("/update-customer")}
            >
              Update Customer
            </div>

            <div
              className="dropdown-item"
              onClick={() => navigate("/delete-customer")}
            >
              Delete Customer
            </div>
          </div>
        )}
      </div>

      {/* Menu Dropdown */}
      <div className="nav-item-dropdown">
        <div
          className="nav-item menu-header"
          onClick={() => setIsMenuDropdownOpen(!isMenuDropdownOpen)}
        >
          Menu
          <span
            className={`dropdown-arrow ${
              isMenuDropdownOpen ? "open" : ""
            }`}
          >
          </span>
        </div>

        {isMenuDropdownOpen && (
          <div className="dropdown-menu">

            <div
              className="dropdown-item"
              onClick={() => navigate("/add-dish")}
            >
              Add Menu
            </div>

            <div
              className="dropdown-item"
              onClick={() => navigate("/update-menu")}
            >
              Update Menu
            </div>

            <div
              className="dropdown-item"
              onClick={() => navigate("/delete-menu")}
            >
              Delete Menu
            </div>
          </div>
        )}
      </div>


      {/* Order Dropdown */}
      <div className="nav-item-dropdown">
        <div
          className="nav-item order-header"
          onClick={() => setIsOrderDropdownOpen(!isOrderDropdownOpen)}
        >
          Order
          <span
            className={`dropdown-arrow ${
              isOrderDropdownOpen ? "open" : ""
            }`}
          >
          </span>
        </div>

        {isOrderDropdownOpen && (
          <div className="dropdown-menu">
            <div
              className="dropdown-item"
              onClick={() => navigate("/add-order")}
            >
              Add Order
            </div>

            <div
              className="dropdown-item"
              onClick={() => navigate("/update-order")}
            >
              Update Order
            </div>

            <div
              className="dropdown-item"
              onClick={() => navigate("/delete-order")}
            >
              Delete Order
            </div>
          </div>
        )}
      </div>  

      {/* Payment Dropdown */}
      <div className="nav-item-dropdown">
        <div
          className="nav-item payment-header"
          onClick={() => setIsPaymentDropdownOpen(!isPaymentDropdownOpen)}
        >
          Payment
          <span
            className={`dropdown-arrow ${
              isPaymentDropdownOpen ? "open" : ""
            }`}
          >
          </span>
        </div>

        {isPaymentDropdownOpen && (
          <div className="dropdown-menu">
            <div
              className="dropdown-item"
              onClick={() => navigate("/add-payment")}
            >
              Add Payment
            </div>

            <div
              className="dropdown-item"
              onClick={() => navigate("/update-payment")}
            >
              Update Payment
            </div>

            <div
              className="dropdown-item"
              onClick={() => navigate("/delete-payment")}
            >
              Delete Payment
            </div>
          </div>
        )}
      </div>

      {/* Report Dropdown */}
      <div className="nav-item-dropdown">
        <div
          className="nav-item report-header"
          onClick={() => setIsReportDropdownOpen(!isReportDropdownOpen)}
        >
          Report
          <span
            className={`dropdown-arrow ${
              isReportDropdownOpen ? "open" : ""
            }`}
          >
          </span>
        </div>

        {isReportDropdownOpen && (
          <div className="dropdown-menu">
            <div
              className="dropdown-item"
              onClick={() => handleReportClick("todayReport")}
            >
              Today's Report
            </div>

            <div
              className="dropdown-item"
              onClick={() => handleReportClick("monthlyReport")}
            >
              Monthly Report
            </div>

            <div
              className="dropdown-item"
              onClick={() => handleReportClick("yearlyReport")}
            >
              Yearly Report
            </div>
          </div>
        )}
      </div>

    </div>
  );
}

export default Sidebar;