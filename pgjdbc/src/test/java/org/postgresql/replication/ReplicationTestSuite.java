package org.postgresql.replication;

import org.postgresql.core.ServerVersion;
import org.postgresql.test.TestUtil;
import org.postgresql.test.jdbc2.CopyBothResponseTest;

import org.junit.AssumptionViolatedException;
import org.junit.BeforeClass;
import org.junit.runner.RunWith;
import org.junit.runners.Suite;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

@RunWith(Suite.class)
@Suite.SuiteClasses({
    CopyBothResponseTest.class,
    LogicalReplicationTest.class,
    LogSequenceNumberTest.class,
    PhysicalReplicationTest.class})
public class ReplicationTestSuite {

  @BeforeClass
  public static void setUp() throws Exception {
    Connection connection = TestUtil.openDB();
    try {
      if (TestUtil.haveMinimumServerVersion(connection, ServerVersion.v9_0)) {
        Statement stmt = connection.createStatement();
        ResultSet rs = stmt.executeQuery("SHOW max_wal_senders");
        rs.next();
        int maxWalSenders = rs.getInt(1);
        rs.close();
        stmt.close();

        if (maxWalSenders == 0) {
          throw new AssumptionViolatedException("Skip replication test because max_wal_senders = 0");
        }

      } else {
        throw new AssumptionViolatedException(
            "Skip replication test because current database version "
                + "too old and don't contain replication API"
        );
      }
    } finally {
      connection.close();
    }
  }
}