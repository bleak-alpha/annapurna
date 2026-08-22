import React, { useState, useMemo, useEffect, useRef } from "react";
import { AgGridReact } from "ag-grid-react";
import { ModuleRegistry, AllCommunityModule } from "ag-grid-community";
import { getCustomerCache, saveOrder, getMenuCache, getOrders } from "../api/api";
import CustomerEditor from "./Suggestion/CustomerEditor";
import MenuEditor from "./Suggestion/MenuEditor";
import { connectWebSocket, disconnectWebSocket, sendOrderUpdate, } from "../websocket";


ModuleRegistry.registerModules([AllCommunityModule]);

const OrderSheet = () => {
  const createEmptyRow = (srNo = 1) => ({
    id: null,
    srNo,
    customerName: "",
    customerId: "",
    tableNo: "",
    orders: [],
    totalPayment: 0,
    paymentMethod: "PENDING",
    previousDuePayment: "",
    status: "PENDING",
    hasBeenSaved: false,
  });

  useEffect(() => {

    connectWebSocket((updatedOrder) => {

      console.log("Received :", updatedOrder);

      setRowData((prev) => {

        const rows = [...prev];

        const index = rows.findIndex(r => r.id === updatedOrder.id);

        if (index !== -1) {

rows[index] = {
  ...rows[index],       // keep existing values
  ...updatedOrder,      // update changed values
  srNo: rows[index].srNo,
  hasBeenSaved: true,
};

        } else {

          rows.splice(rows.length - 1, 0, {
            ...updatedOrder,
            srNo: rows.length,
            hasBeenSaved: true,
          });

        }

        return rows;

      });

    });

    return () => disconnectWebSocket();

  }, []);

  const [rowData, setRowData] = useState([createEmptyRow()]);

  const gridRef = useRef(null);

  const onGridReady = (params) => {
    gridRef.current = params.api;
  };

  const [customers, setCustomers] = useState([]);

  // =========================
  // LOAD CUSTOMERS
  // =========================
  useEffect(() => {
    loadCustomers();
  }, []);

  useEffect(() => {
    loadOrders();
  }, []);

  const loadOrders = async () => {
    try {
      const data = await getOrders();

      console.log("Orders =", data);

      if (Array.isArray(data) && data.length > 0) {

        const rows = data.map((item, index) => ({
          ...item,
          srNo: index + 1,
          hasBeenSaved: true,
        }));

        // Add one blank row for new order
        rows.push(createEmptyRow(rows.length + 1));

        setRowData(rows);

      } else {

        // API returned null or []
        setRowData([createEmptyRow()]);

      }

    } catch (error) {

      console.error(error);

      setRowData([createEmptyRow()]);

    }
  };

  const loadCustomers = async () => {
    try {
      const data = await getCustomerCache();
      console.log("Customer Cache:", data);

      const list = Array.isArray(data)
        ? data
        : data?.customers || data?.data || [];

      console.log("Processed Customer List:", list);
      setCustomers(list);
    } catch (error) {
      console.error("Error loading customers:", error);
    }
  };

  // =========================
  // LOAD MENU
  // =========================
  const [menu, setMenu] = useState([]);

  useEffect(() => {
    loadMenu();
  }, []);

  const loadMenu = async () => {
    try {
      const data = await getMenuCache();
      console.log("Menu :", data);

      const list = Array.isArray(data)
        ? data
        : data.Menu || data?.data || [];

      console.log("List of Menu : ", list);
      setMenu(list);
    } catch (error) {
      console.error("Error Occured while Loading data :", error);
    }
  };

  // =========================
  // TABLE POPUP
  // =========================
  const [tablePopup, setTablePopup] = useState({
    open: false,
    left: 0,
    top: 0,
    params: null,
  });

  const openTablePopup = (button, params) => {
    const rect = button.getBoundingClientRect();
    setTablePopup({
      open: true,
      left: rect.left,
      top: rect.bottom + 5,
      params,
    });
  };

  const closeTablePopup = () => {
    setTablePopup({
      open: false,
      left: 0,
      top: 0,
      params: null,
    });
  };

  // =========================
  // PAYMENT BUTTON
  // =========================
  const paymentRenderer = (params) => {
    const value = params.value || "PENDING";

    const toggle = () => {
      let nextValue;

      if (value === "PENDING") {
        nextValue = "CASH";
      } else if (value === "CASH") {
        nextValue = "ONLINE";
      } else {
        nextValue = "PENDING";
      }

      params.node.setDataValue("paymentMethod", nextValue);
      sendOrderUpdate(params.node.data);
    };

    let bgColor = "#e91c0d"; // Red

    if (value === "CASH") {
      bgColor = "#f59e0b"; // Orange
    } else if (value === "ONLINE") {
      bgColor = "#3b82f6"; // Blue
    }

    return (
      <button
        onClick={toggle}
        style={{
          padding: "5px 10px",
          borderRadius: "6px",
          border: "none",
          cursor: "pointer",
          backgroundColor: bgColor,
          color: "white",
          fontWeight: "bold",
          width: "100px",
        }}
      >
        {value}
      </button>
    );
  };

  // =========================
  // STATUS BUTTON
  // =========================
  const statusRenderer = (params) => {
    const value = params.value || "PENDING";

const toggle = () => {
  const ready = isOrderComplete(params.data);


  if (!isOrderComplete(params.data)) {
    alert("Please complete all order details first.");
    return;
  }

  const newStatus =
    value === "PENDING" ? "COMPLETED" : "PENDING";

  params.node.setDataValue("status", newStatus);

  sendOrderUpdate({
    ...params.node.data,
    status: newStatus,
  });
    };

    return (
      <button
        onClick={toggle}
        style={{
          padding: "5px 10px",
          borderRadius: "6px",
          border: "none",
          cursor: "pointer",
          backgroundColor: value === "COMPLETED" ? "green" : "red",
          color: "white",
          fontWeight: "bold",
        }}
      >
        {value}
      </button>
    );
  };

  // =========================
  // EDIT RULES
  // =========================
  const isCellEditable = (params) => {
    const { status, hasBeenSaved } = params.data || {};
    const field = params.colDef.field;

    if (!hasBeenSaved) return true;
    if (status === "COMPLETED") return false;

    if (status === "PENDING") {
      const allowed = ["orders", "totalPayment"];
      return allowed.includes(field);
    }

    return false;
  };

  // =========================
  // COLUMN DEFINITIONS
  // =========================
  const columnDefs = useMemo(
    () => [
      {
        headerName: "SR NO",
        field: "srNo",
        minWidth: 5,
      },
      {
        headerName: "Customer Name",
        field: "customerName",
        editable: true,
        cellEditor: CustomerEditor,
        cellEditorPopup: true,
        cellEditorParams: {
          customers: customers,
        },
      },
      {
        headerName: "Customer ID",
        field: "customerId",
        editable: isCellEditable,
      },
      {
        headerName: "Table No",
        field: "tableNo",
        flex: 2,
        minWidth: 180,
        cellRenderer: (params) => {
          if (params.value) {
            return <span>{params.value}</span>;
          }

          return (
            <div className="table-cell-buttons">
              <button
                className="parcel-btn"
                onClick={() => {
                  params.node.setDataValue("tableNo", "Parcel");
                  sendOrderUpdate(params.node.data);
                }}

              >
                Parcel
              </button>

              <button
                className="table-btn"
                onClick={(e) => openTablePopup(e.currentTarget, params)}
              >
                Table No
              </button>
            </div>
          );
        },
      },
      {
        headerName: "Order",
        field: "orders",
        flex: 3,
        minWidth: 300,
        editable: true,
        wrapText: true,
        autoHeight: true,
        cellEditor: MenuEditor,
        cellEditorPopup: true,
            cellEditorPopupPosition: "over",
        cellRenderer: (params) => {
          const addDish = () => {
            params.api.startEditingCell({
              rowIndex: params.node.rowIndex,
              colKey: "orders",
            });
          };
const toggleDishStatus = (index) => {
    const orders = [...(params.data.orders || [])];

    orders[index] = {
        ...orders[index],
        served: !orders[index].served,
    };

    const updatedRow = {
        ...params.node.data,
        orders,
    };

    params.node.setData(updatedRow);

    sendOrderUpdate(updatedRow);
    console.log("Updated Orderrs:", updatedRow);

    params.api.refreshCells({
        rowNodes: [params.node],
        force: true,
    });
};
          console.log("Orders in Cell Renderer:", params.data.orders);
          const updateOrder = (index, action) => {
            const orders = [...(params.data.orders || [])];
            console.log("Before Update:", orders);

            if (action === "plus") {
                  console.log("PLUS CLICKED", index);
              orders[index].qty++;
            }

            if (action === "minus") {
              if (orders[index].qty > 1) {
                orders[index].qty--;
              } else {
                orders.splice(index, 1);
              }
            }

            if (action === "delete") {
              orders.splice(index, 1);
            }

            const total = orders.reduce(
              (sum, item) => sum + item.cost * item.qty,
              0
            );

            params.node.setDataValue("orders", orders);
            params.node.setDataValue("totalPayment", total);
            const updatedRow = {
    ...params.node.data,
    orders,
    totalPayment: total,
};

params.node.setData(updatedRow);

sendOrderUpdate(updatedRow); 
            // params.node.setData(params.node.data);

            // sendOrderUpdate(params.node.data);

            params.api.refreshCells({
              rowNodes: [params.node],
              force: true,
            });
          };

          return (
            <div style={{ padding: "4px" }}>
              {(params.value || []).map((item, index) => (
                <div
                  key={index}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    gap: "10px",
                    marginBottom: "8px",
                  }}
                >
                  {/* Dish Name */}
                  <div
                    onClick={() => toggleDishStatus(index)}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "10px",
                      border: "1px solid #d1d5db",
                      borderRadius: "8px",
                      padding: "6px 10px",
                      minWidth: "170px",
                      cursor: "pointer",
                      background: "#fff",
                      transition: "0.3s",
                    }}
                  >
                    {/* Status Circle */}
                    <div
                      style={{
                        width: "12px",
                        height: "12px",
                        borderRadius: "50%",
                        backgroundColor: item.served ? "#22c55e" : "#ef4444",
                        transform: item.served ? "scale(1.2)" : "scale(1)",
                        transition: "all .25s ease",
                        boxShadow: item.served
                          ? "0 0 8px #22c55e"
                          : "0 0 8px #ef4444",
                      }}
                    />

                    <span
                      style={{
                        fontWeight: "600",
                        color: "#333",
                      }}
                    >
                      {item.itemDescription}
                    </span>
                  </div>

                  {/* Quantity Controls */}
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "6px",
                    }}
                  >
{params.data.status !== "COMPLETED" && (
  <button onClick={() => updateOrder(index, "minus")}>
    −
  </button>
)}

                    <span
                      style={{
                        minWidth: "18px",
                        textAlign: "center",
                        fontWeight: "bold",
                      }}
                    >
                      {item.qty}
                    </span>

                   {params.data.status !== "COMPLETED" && (
  <button onClick={() => updateOrder(index, "plus")}>
    +
  </button>
)}

                    {params.data.status !== "COMPLETED" && (
  <button onClick={() => updateOrder(index, "delete")}>
    ✕
  </button>
)}
                  </div>
                </div>
              ))}

              {/* Add Dish Button */}
              {params.data.status !== "COMPLETED" && (
  <div
    style={{
      display: "flex",
      justifyContent: "flex-start",
      marginTop: "8px",
    }}
  >
    <button
      onClick={addDish}
      style={{
        background: "#1976d2",
        color: "#fff",
        border: "none",
        borderRadius: "5px",
        padding: "5px 12px",
        cursor: "pointer",
      }}
    >
      + Add Dish
    </button>
  </div>
)}
            </div>
          );
        },
        cellEditorParams: {
          menu,
        },
      },
      {
        headerName: "Total Payment",
        field: "totalPayment",
        editable: isCellEditable,
        cellDataType: "number",
        minWidth: 80
     },
      {
        headerName: "Payment Method",
        field: "paymentMethod",
        cellRenderer: paymentRenderer,
        editable: false,
      },
      {
        headerName: "Previous Due",
        field: "previousDuePayment",
        editable: false,
        minWidth: 80,
      },
      {
        headerName: "Status",
        field: "status",
        cellRenderer: statusRenderer,
        editable: false,
      },
      
    ],
    [customers]
  );

  // =========================
  // DEFAULT GRID CONFIG
  // =========================
  const defaultColDef = useMemo(
    () => ({
      flex: 1,
      minWidth: 120,
      resizable: true,
      sortable: true,
      filter: true,
    }),
    []
  );

  // =========================
  // ADD ROW
  // =========================
  const addRow = async () => {
    try {
      let currentRow = rowData[rowData.length - 1];

      if (currentRow.id == null) {
        const response = await saveOrder(currentRow);
        const savedOrder = {
          ...currentRow,
          id: response.id,
          hasBeenSaved: true,
        };

        sendOrderUpdate(savedOrder);
        setRowData(prev => [
          ...prev.slice(0, prev.length - 1),
          {
            ...currentRow,
            id: response.id,
            hasBeenSaved: true,
          },

          createEmptyRow(prev.length + 1)
        ]);
      }
      setTimeout(() => {
        gridRef.current?.ensureIndexVisible(rowData.length, "bottom");
      }, 100);
    } catch (error) {
      console.error(error);
      alert("Failed to save order.");
    }
  };

  useEffect(() => {
    if (gridRef.current && rowData.length > 0) {
      setTimeout(() => {
        gridRef.current.ensureIndexVisible(rowData.length - 1, "bottom");
      }, 100);
    }
  }, [rowData.length]);

  // =========================
  // CELL VALUE CHANGED
  // =========================
  const onCellValueChanged = (params) => {
    if (
      params.colDef.field === "status" &&
      params.newValue === "COMPLETED"
    ) {
      params.node.setDataValue("hasBeenSaved", true);
    }

  };


  // =========================
  // CELL EDITING STOPPED (⭐ NEW - Approach 3)
  // =========================
  const onCellEditingStopped = (params) => {
    const { field, data, node } = params;

    // Only handle customerName column
    if (field === "customerName") {
      const customerName = data.customerName?.trim();
      const customerId = data.customerId;

      console.log("Editing stopped for customerName:", {
        customerName,
        customerId,
      });

      // If name is empty, clear the ID
      if (!customerName) {
        node.setDataValue("customerId", "");
        return;
      }

      // If no customer ID was set (user didn't select from suggestions and didn't press Enter)
      // This shouldn't happen with new approach, but keeping as safety net
      if (!customerId) {
        node.setDataValue("customerId", `TEMP-${Date.now()}`);
      }
    }
    sendOrderUpdate(node.data);

  };

  return (
    <div style={{ padding: 20 }}>
      <h2>Order Sheet</h2>

      <div
        className="ag-theme-quartz"
        style={{ height: 490, width: "100%", position: "relative" }}
      >
        <AgGridReact
          ref={gridRef}
          onGridReady={onGridReady}
          rowData={rowData}
          columnDefs={columnDefs}
          defaultColDef={defaultColDef}
          getRowHeight={(params) => {
            const count = params.data.orders?.length || 1;
            return Math.max(50, count * 38);
          }}
          headerHeight={50}
          onCellValueChanged={onCellValueChanged}
          onCellEditingStopped={onCellEditingStopped}
          popupParent={document.body}
          
        />

        {tablePopup.open && (
          <div
            className="table-popup"
            style={{
              left: tablePopup.left,
              top: tablePopup.top,
            }}
          >
            <input
              autoFocus
              placeholder="Enter Table No"
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  tablePopup.params.node.setDataValue(
                    "tableNo",
                    `Table ${e.target.value}`
                  );
                  sendOrderUpdate(tablePopup.params.node.data);
                  closeTablePopup();
                }
              }}
            />

            <button onClick={closeTablePopup}>✕</button>
          </div>
        )}
      </div>

      {/* Add Row Button */}
      <div style={{ marginTop: "15px", textAlign: "right" }}>
        <button
          onClick={addRow}
          style={{
            background: "#1976d2",
            color: "#fff",
            border: "none",
            padding: "10px 20px",
            borderRadius: "6px",
            cursor: "pointer",
            fontWeight: "600",
          }}
        >
          + Add Row
        </button>
      </div>
    </div>
  );
};




const isOrderComplete = (row) => {
    if (!row.customerName?.trim()) return false;
    if (!row.orders || row.orders.length === 0) return false;
    if (row.totalPayment <= 0) return false;
    if (!row.paymentMethod || row.paymentMethod === "PENDING") return false;
    return true;
}


export default OrderSheet;