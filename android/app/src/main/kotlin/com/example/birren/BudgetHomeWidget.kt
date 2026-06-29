package com.example.birren

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity
import org.json.JSONArray
import org.json.JSONObject

private val BackgroundColor = Color(0xFF19173D)
private val AccentColor = Color(0xFF00D7FF)
private val DividerColor = Color(0x3DFFFFFF)
private val TrackColor = Color(0x1FFFFFFF)

private val WhiteText = ColorProvider(Color.White)
private val MutedText = ColorProvider(Color(0xB3FFFFFF))

private data class LineItemSnapshot(
    val name: String,
    val spent: String,
    val allocated: String,
    val progress: Float,
    val color: ColorProvider,
)

private data class BudgetSnapshot(
    val hasBudget: Boolean,
    val name: String = "",
    val dateRange: String = "",
    val total: String = "",
    val spent: String = "",
    val remaining: String = "",
    val isExpired: Boolean = false,
    val lineItems: List<LineItemSnapshot> = emptyList(),
)

class BudgetHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                BudgetWidgetContent(context, currentState())
            }
        }
    }
}

private fun parseSnapshot(raw: String?): BudgetSnapshot {
    if (raw.isNullOrBlank()) {
        return BudgetSnapshot(hasBudget = false)
    }

    return try {
        val json = JSONObject(raw)
        val hasBudget = json.optBoolean("hasBudget", false)
        if (!hasBudget) {
            return BudgetSnapshot(hasBudget = false)
        }

        val lineItems = mutableListOf<LineItemSnapshot>()
        val itemsArray = json.optJSONArray("lineItems") ?: JSONArray()
        for (index in 0 until itemsArray.length()) {
            val item = itemsArray.getJSONObject(index)
            lineItems.add(
                LineItemSnapshot(
                    name = item.optString("name", ""),
                    spent = item.optString("spent", "0.00"),
                    allocated = item.optString("allocated", "0.00"),
                    progress = item.optDouble("progress", 0.0).toFloat(),
                    color = colorFromName(item.optString("color", "green")),
                ),
            )
        }

        BudgetSnapshot(
            hasBudget = true,
            name = json.optString("name", ""),
            dateRange = json.optString("dateRange", ""),
            total = json.optString("total", "0.00"),
            spent = json.optString("spent", "0.00"),
            remaining = json.optString("remaining", "0.00"),
            isExpired = json.optBoolean("isExpired", false),
            lineItems = lineItems,
        )
    } catch (_: Exception) {
        BudgetSnapshot(hasBudget = false)
    }
}

private fun colorFromName(name: String): ColorProvider {
    return when (name) {
        "red" -> ColorProvider(Color(0xFFF44336))
        "amber" -> ColorProvider(Color(0xFFFFC107))
        else -> ColorProvider(Color(0xFF4CAF50))
    }
}

@Composable
private fun BudgetWidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
    val snapshot = parseSnapshot(
        currentState.preferences.getString(BudgetWidgetKeys.SNAPSHOT, null),
    )

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(BackgroundColor)
            .padding(16.dp)
            .clickable(onClick = actionStartActivity<MainActivity>(context)),
    ) {
        if (!snapshot.hasBudget) {
            NoBudgetContent(context)
        } else {
            BudgetContent(context, snapshot)
        }
    }
}

@Composable
private fun NoBudgetContent(context: Context) {
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Box(
            modifier = GlanceModifier
                .width(48.dp)
                .height(48.dp)
                .cornerRadius(24.dp)
                .background(AccentColor),
            contentAlignment = Alignment.Center,
        ) {
            Text("B", style = TextStyle(color = WhiteText, fontWeight = FontWeight.Bold))
        }
        Spacer(GlanceModifier.width(16.dp))
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text("No active budget", style = TextStyle(color = WhiteText, fontSize = 16.sp))
            Spacer(GlanceModifier.height(4.dp))
            Text(
                "Create a budget with a date range and categories.",
                style = TextStyle(color = MutedText, fontSize = 13.sp),
            )
        }
        Spacer(GlanceModifier.width(8.dp))
        Text(
            "Create",
            modifier = GlanceModifier.clickable(
                onClick = actionStartActivity<MainActivity>(
                    context,
                    Uri.parse("birren://add-budget"),
                ),
            ),
            style = TextStyle(color = WhiteText, fontWeight = FontWeight.Bold, fontSize = 14.sp),
        )
    }
}

@Composable
private fun BudgetContent(context: Context, snapshot: BudgetSnapshot) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Vertical.Top,
        ) {
            Box(
                modifier = GlanceModifier
                    .width(48.dp)
                    .height(48.dp)
                    .cornerRadius(24.dp)
                    .background(if (snapshot.isExpired) Color.Gray else AccentColor),
                contentAlignment = Alignment.Center,
            ) {
                Text("B", style = TextStyle(color = WhiteText, fontWeight = FontWeight.Bold))
            }
            Spacer(GlanceModifier.width(16.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(snapshot.name, style = TextStyle(color = WhiteText, fontSize = 16.sp))
                Spacer(GlanceModifier.height(4.dp))
                Text(
                    snapshot.dateRange,
                    style = TextStyle(color = MutedText, fontSize = 13.sp),
                )
                if (snapshot.isExpired) {
                    Spacer(GlanceModifier.height(4.dp))
                    Text(
                        "Budget period ended",
                        style = TextStyle(color = MutedText, fontSize = 12.sp),
                    )
                }
            }
            if (snapshot.isExpired) {
                Text(
                    "New cycle",
                    modifier = GlanceModifier.clickable(
                        onClick = actionStartActivity<MainActivity>(
                            context,
                            Uri.parse("birren://add-budget"),
                        ),
                    ),
                    style = TextStyle(color = WhiteText, fontWeight = FontWeight.Bold, fontSize = 14.sp),
                )
            }
        }

        Spacer(GlanceModifier.height(12.dp))

        Row(modifier = GlanceModifier.fillMaxWidth()) {
            StatColumn("Total", "${snapshot.total} birr", GlanceModifier.defaultWeight())
            StatColumn("Spent", "${snapshot.spent} birr", GlanceModifier.defaultWeight())
            StatColumn("Left", "${snapshot.remaining} birr", GlanceModifier.defaultWeight())
        }

        if (snapshot.lineItems.isNotEmpty()) {
            Spacer(GlanceModifier.height(12.dp))
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(DividerColor),
            ) {}
            Spacer(GlanceModifier.height(8.dp))
            Text("Budget items", style = TextStyle(color = WhiteText, fontSize = 14.sp))
            Spacer(GlanceModifier.height(8.dp))
            LazyColumn {
                items(snapshot.lineItems) { item ->
                    LineItemRow(item)
                    Spacer(GlanceModifier.height(6.dp))
                }
            }
        }
    }
}

@Composable
private fun StatColumn(label: String, value: String, modifier: GlanceModifier) {
    Column(modifier = modifier.padding(horizontal = 4.dp)) {
        Text(label, style = TextStyle(color = WhiteText, fontSize = 14.sp))
        Spacer(GlanceModifier.height(4.dp))
        Text(value, style = TextStyle(color = MutedText, fontSize = 13.sp))
    }
}

@Composable
private fun LineItemRow(item: LineItemSnapshot) {
    val progress = item.progress.coerceIn(0f, 1f)
    val filledSegments = (progress * 10f).toInt().coerceIn(0, 10)

    Column(modifier = GlanceModifier.fillMaxWidth().padding(vertical = 6.dp, horizontal = 4.dp)) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            Text(
                item.name,
                modifier = GlanceModifier.defaultWeight(),
                style = TextStyle(color = WhiteText, fontSize = 14.sp),
            )
            Text(
                "${item.spent} / ${item.allocated}",
                style = TextStyle(color = WhiteText, fontSize = 14.sp),
            )
        }
        Spacer(GlanceModifier.height(6.dp))
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(6.dp)
                .cornerRadius(4.dp),
        ) {
            repeat(10) { index ->
                val segmentColor = if (index < filledSegments) item.color else ColorProvider(TrackColor)
                Box(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight()
                        .padding(horizontal = 1.dp)
                        .cornerRadius(2.dp)
                        .background(segmentColor),
                ) {}
            }
        }
    }
}

object BudgetWidgetKeys {
    const val SNAPSHOT = "budget_snapshot"
}
