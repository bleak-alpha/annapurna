const BASE_URL = 'http://localhost:8080/api';

export async function addMenu(formData) {
    const response = await fetch(`${BASE_URL}/menu/add`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
    });

    if (!response.ok) {
        throw new Error('Failed to add menu');
    }
    return response.json();
}


export async function addCustomer(formData) {
    const response = await fetch(`${BASE_URL}/customers`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
    });

    if (!response.ok) {
        throw new Error('Failed to add customer');
    }
    return response.json();
}

// Report API Endpoints
export async function getTodayReport() {
    const response = await fetch(`${BASE_URL}/reports/today`, {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json'
        }
    });

    if (!response.ok) {
        throw new Error('Failed to fetch today report');
    }
    return response.json();
}


export async function getPendingOrders() {
    const response = await fetch(`${BASE_URL}/orders/pending`, {
        method: "GET",
        headers: {
            "Content-Type": "application/json",
        },
    });

    if (!response.ok) {
        throw new Error("Failed to fetch pending orders");
    }

    const data = await response.json(); 
    // Ensure we always return an array to the caller
    if (!data || !Array.isArray(data)) {
        return [];
    }

    return data;
}


export const getCustomerCache = async () => {
    const response = await fetch(
        `${BASE_URL}/customers/fetchallcustomers`
    );

    if (!response.ok) {
        throw new Error("Failed to fetch customers");
    }

    return await response.json();
};

export const getMenuCache = async () => {
    const response = await fetch(
        `${BASE_URL}/menu`
    );
    console.log("Menu Cache Response:", response);

    if (!response.ok) {
        throw new Error("Failed to fetch menu");
    }

    return await response.json();
};

export const saveOrder = async (data) => {
  const response = await fetch(`${BASE_URL}/dashboard/updateOrder`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    throw new Error("Failed to save order");
  }

  const result = await response.json();

  console.log("API Result:", result);

  return result;
};


export const getOrders = async () => {
  const response = await fetch(`${BASE_URL}/dashboard/dashboardData`);

  if (!response.ok) {
    throw new Error("Failed to fetch orders");
  }

  return await response.json();
};
