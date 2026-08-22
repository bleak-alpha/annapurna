import { useState } from 'react';

function Report() {
  const [reportType, setReportType] = useState('todayReport');

  return (
    <div className="report-container">
      <h2>Reports</h2>
      
      <div className="report-selector">
        <select 
          value={reportType} 
          onChange={(e) => setReportType(e.target.value)}
          className="report-dropdown"
        >
          <option value="todayReport">Today's Report</option>
          <option value="monthlyReport">Monthly Report</option>
          <option value="yearlyReport">Yearly Report</option>
        </select>
      </div>

      <div className="report-content">
        {/* Your API content will go here */}
      </div>
    </div>
  );
}

export default Report;
           